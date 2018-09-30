defmodule Influx.Adapters.HTTPX do
  @moduledoc ~S"""
  HTTPX Influx adapter.
  """
  @behaviour Influx.Adapter

  @impl Influx.Adapter
  def query(host, query, opts) do
    url = url(host, "query")
    query = prepare_query(query)

    case {perform_get(url, query, opts), perform_post(url, query, opts)} do
      {get, []} -> get
      {[], post} -> post
      {get, {:ok, %{data: data}}} -> %{get | data: get.data ++ data}
    end
  end

  @impl Influx.Adapter
  def write(host, write, opts) do
    with {:ok, response} <- HTTPX.post(url(host, "write"), write, params: opts) do
      parse_response(response)
    end
  end

  @impl Influx.Adapter
  def ping(host),
    do: with({:ok, response} <- HTTPX.get(url(host, "ping")), do: parse_response(response))

  @impl Influx.Adapter
  def debug(host) do
    with {:ok, response} <- HTTPX.get(url(host, "debug/vars"), format: :json_atoms) do
      parse_response(response)
    end
  end

  @impl Influx.Adapter
  def requests(host, duration \\ 10) do
    with {:ok, http} <-
           HTTPX.get(url(host, "debug/requests"), params: %{seconds: duration}, format: :json),
         {:ok, response} <- parse_response(http) do
      {:ok,
       %{
         response
         | data:
             Enum.into(response.data, %{}, fn {k, %{"writes" => w, "queries" => q}} ->
               {k, %{writes: w, queries: q}}
             end)
       }}
    end
  end

  @impl Influx.Adapter
  def profile(host, profile \\ :all)

  def profile(host, :all) do
    with {:ok, http} <- HTTPX.get(url(host, "debug/pprof/all")),
         {:ok, response} <- parse_response(http),
         {:ok, data} <- :erl_tar.extract({:binary, :zlib.gunzip(response.data)}, [:memory]) do
      data =
        Enum.into(data, %{}, fn {k, v} ->
          {String.to_atom(String.trim_trailing(to_string(k), ".txt")), v}
        end)

      {:ok, %{response | data: data}}
    end
  end

  def profile(host, profile) do
    with {:ok, http} <- HTTPX.get(url(host, "debug/pprof/#{profile}"), params: %{debug: 1}),
         {:ok, response} <- parse_response(http) do
      {:ok, %{response | data: Map.put(%{}, profile, response.data)}}
    end
  end

  ### Adapter Specific Helpers ###

  @spec url(URI.t() | String.t(), String.t()) :: String.t()
  defp url(host, path), do: host |> URI.merge(path) |> to_string()

  @request_id "X-Request-Id"
  @build_header "X-Influxdb-Build"
  @version_header "X-Influxdb-Version"
  @builds %{
    "OSS" => :open_source,
    "ENT" => :enterprise
  }

  alias HTTPX.Response
  @spec parse_response(HTTPX.Response.t()) :: :ok | {:error, atom}
  defp parse_response(response = %Response{status: 204}) do
    {:ok,
     %Influx.Response{
       id: get_header(response, @request_id),
       version: get_header(response, @version_header, ""),
       build: @builds[get_header(response, @build_header, "OSS")]
     }}
  end

  defp parse_response(response = %Response{status: status, body: body}) when status in 200..203 do
    {:ok,
     %Influx.Response{
       id: get_header(response, @request_id),
       version: get_header(response, @version_header, ""),
       build: @builds[get_header(response, @build_header, "OSS")],
       data: body
     }}
  end

  defp parse_response(response = %Response{status: _, body: %{"error" => error}}) do
    {:error, %Influx.Error{id: get_header(response, @request_id), message: error}}
  end

  defp parse_response(response = %Response{status: _, body: error}) do
    case Jason.decode(error) do
      {:ok, %{"error" => error}} ->
        {:error, %Influx.Error{id: get_header(response, @request_id), message: error}}

      _ ->
        {:error, :request_error}
    end
  end

  defp get_header(_response = %HTTPX.Response{headers: headers}, header, default \\ nil) do
    Enum.find_value(headers, default, fn {k, v} -> if k == header, do: v end)
  end

  defp prepare_query(query) do
    query
    |> String.split(";", trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.group_by(&group_query/1)
  end

  defp group_query(select = "SELECT " <> _), do: if(select =~ ~r/INTO/i, do: :post, else: :get)
  defp group_query("SHOW " <> _), do: :get
  defp group_query(_), do: :post

  defp perform_get(url, %{get: queries}, opts) do
    query = Enum.join(queries, ";")

    with {:ok, http} <- HTTPX.get(url, params: Map.put(opts, :q, query), format: :json),
         {:ok, response = %{data: %{"results" => results}}} <- parse_response(http) do
      data =
        results
        |> Enum.map(&parse_query_result(response.id, &1))
        |> Enum.zip(queries)
        |> Enum.map(fn {r, q} -> %{result: r, query: q} end)

      {:ok, %{response | data: data}}
    end
  end

  defp perform_get(_, _, _), do: []

  defp perform_post(url, %{post: queries}, opts) do
    query = {:urlencoded, %{q: Enum.join(queries, ";")}}

    with {:ok, http} <- HTTPX.post(url, query, params: opts, format: :json),
         {:ok, response = %{data: %{"results" => results}}} <- parse_response(http) do
      data =
        results
        |> Enum.map(&parse_query_result(response.id, &1))
        |> Enum.zip(queries)
        |> Enum.map(fn {r, q} -> %{result: r, query: q} end)

      {:ok, %{response | data: data}}
    end
  end

  defp perform_post(_, _, _), do: []

  defp parse_query_result(id, %{"error" => error}) do
    {:error, %Influx.Error{id: id, message: error}}
  end

  defp parse_query_result(_id, %{"series" => series}) do
    series = List.first(series)

    {:ok,
     %{
       name: series["name"],
       columns: series["columns"] || [],
       values: series["values"] || []
     }}
  end

  defp parse_query_result(_id, %{"statement_id" => _}) do
    :ok
  end
end
