defmodule Influx do
  @moduledoc Influx.Docs.influx()
  require Influx.Util
  import Influx.Util, only: [bangify!: 1, safe_in: 2]
  import Influx.Config, only: [write_options: 1]

  ### Types ###

  @typedoc ~S"Influx host url."
  @type host :: URI.t() | String.t()

  @typedoc ~S"Influx write option."
  @type write_option ::
          :database | :username | :password | :precision | :consistency | :retention_policy

  @typedoc ~S"Influx write options."
  @type write_options :: [{write_option, term}]

  @typedoc ~S"Influx request error."
  @type error :: {:error, atom | Influx.Error.t()}

  @typedoc ~S"Influx write and query response."
  @type result :: {:ok, Influx.Response.t()} | error

  @typedoc ~S"Influx profiling.."
  @type profile :: :all | :block | :goroutine | :heap | :mutex | :threadcreate

  ### ###

  @doc @moduledoc
  defmacro __using__(opts \\ []) do
    otp = opts[:otp_app] || raise "Need to set `otp_app:`."
    adapter = opts[:adapter]

    quote location: :keep do
      unless @moduledoc do
        @moduledoc Influx.Docs.influx()
      end

      @config Application.get_env(unquote(otp), __MODULE__)
      @adapter @config[:adapter] || unquote(adapter) || Influx.Adapters.HTTPX
      @url URI.parse(@config[:url] || "")
      @host to_string(%{
              @url
              | authority: nil,
                fragment: nil,
                query: nil,
                userinfo: nil
            })

      default_opts =
        case String.split(@url.userinfo || "", ":", trim: true) do
          [] -> []
          [user] -> [username: user]
          [user, password] -> [username: user, password: password]
        end

      @default_write_opts if @config[:database],
                            do: Keyword.put(default_opts, :database, @config[:database]),
                            else: default_opts

      @doc Influx.Docs.ping()
      @spec ping :: :ok | Influx.error()
      def ping, do: Influx.ping(@adapter, @host)

      @doc ~S"""
      See `ping/0`.
      """
      @spec ping! :: :ok | no_return
      def ping!, do: Influx.ping(@adapter, @host)

      @doc Influx.Docs.info()
      @spec info :: {:ok, Influx.Info.t()} | Influx.error()
      def info, do: Influx.info(@adapter, @host)

      @doc ~S"""
      See `info/0`.
      """
      @spec info! :: Influx.Info.t() | no_return
      def info!, do: Influx.info!(@adapter, @host)

      @doc Influx.Docs.debug()
      @spec debug(atom | [atom]) :: {:ok, map} | Influx.error()
      def debug(getter \\ []), do: Influx.debug(@adapter, @host, getter)

      @doc ~S"""
      See `debug/0`.
      """
      @spec debug!(atom | [atom]) :: map | no_return
      def debug!(getter \\ []), do: Influx.debug!(@adapter, @host, getter)

      @doc Influx.Docs.requests()
      @spec requests(pos_integer) :: {:ok, map} | Influx.error()
      def requests(duration \\ 10), do: Influx.requests(@adapter, @host, duration)

      @doc ~S"""
      See `requests/0`.
      """
      @spec requests!(pos_integer) :: map | no_return
      def requests!(duration \\ 10), do: Influx.requests!(@adapter, @host, duration)

      @doc Influx.Docs.profile()
      @spec profile(Influx.profile()) :: {:ok, map} | Influx.error()
      def profile(profile \\ :all), do: Influx.profile(@adapter, @host, profile)

      @doc ~S"""
      See `requests/0`.
      """
      @spec profile!(Influx.profile()) :: map | no_return
      def profile!(profile \\ :all), do: Influx.profile!(@adapter, @host, profile)

      @doc Influx.Docs.write()
      @spec write(String.t(), Influx.Config.write_options()) :: :ok | Influx.error()
      def write(write, opts \\ []),
        do: Influx.write(@adapter, @host, write, Keyword.merge(@default_write_opts, opts))

      @doc ~S"""
      See `requests/0`.
      """
      @spec write!(Influx.profile(), Influx.Config.write_options()) :: map | no_return
      def write!(write, opts \\ []),
        do: Influx.write!(@adapter, @host, write, Keyword.merge(@default_write_opts, opts))

      @doc Influx.Docs.write()
      @spec query(String.t(), Influx.Config.write_options()) :: :ok | Influx.error()
      def query(query, opts \\ []),
        do: Influx.query(@adapter, @host, query, Keyword.merge(@default_write_opts, opts))

      @doc ~S"""
      See `requests/0`.
      """
      @spec query!(Influx.profile(), Influx.Config.write_options()) :: map | no_return
      def query!(query, opts \\ []),
        do: Influx.query!(@adapter, @host, query, Keyword.merge(@default_write_opts, opts))

      ### Higher Level ###

      @doc ~S"""
      Select from InfluxDB.

      Still WIP.
      """
      @spec select(String.t() | [String.t()], Keyword.t()) :: {:ok, [map]} | Influx.error()
      def select(fields, opts),
        do: Influx.select(@adapter, @host, fields, Keyword.merge(@default_write_opts, opts))
    end
  end

  @doc Influx.Docs.ping()
  @spec ping(module, host) :: :ok | Influx.error()
  def ping(adapter, host), do: with({:ok, _} <- adapter.ping(host), do: :ok)

  @doc ~S"""
  See `ping/2`.
  """
  @spec ping!(module, host) :: :ok | no_return
  def ping!(adapter, host), do: bangify!(ping(adapter, host))

  @doc Influx.Docs.info()
  @spec info(module, host) :: {:ok, Influx.Info.t()} | Influx.error()
  def info(adapter, host) do
    with {:ok, %{build: build, version: version}} <- adapter.ping(host),
         {:ok, version} <- Version.parse(version || "") do
      {:ok,
       %Influx.Info{
         version: version,
         build: build
       }}
    end
  end

  @doc ~S"""
  See `info/2`.
  """
  @spec info!(module, host) :: Influx.Info.t() | no_return
  def info!(adapter, host), do: bangify!(info(adapter, host))

  @doc Influx.Docs.debug()
  @spec debug(module, host, atom | [atom]) :: {:ok, map} | Influx.error()
  def debug(adapter, host, getter \\ []) do
    with {:ok, %{data: data}} <- adapter.debug(host) do
      {:ok, safe_in(data, getter)}
    end
  end

  @doc ~S"""
  See `debug/3`.
  """
  @spec debug!(module, host, atom | [atom]) :: map | no_return
  def debug!(adapter, host, getter \\ []), do: bangify!(debug(adapter, host, getter))

  @doc Influx.Docs.requests()
  @spec requests(module, host, pos_integer) :: {:ok, map} | Influx.error()
  def requests(adapter, host, duration \\ 10) do
    with {:ok, %{data: data}} <- adapter.requests(host, duration) do
      {:ok, data}
    end
  end

  @doc ~S"""
  See `requests/3`.
  """
  @spec requests!(module, host, pos_integer) :: map | no_return
  def requests!(adapter, host, duration \\ 10), do: bangify!(requests(adapter, host, duration))

  @doc Influx.Docs.profile()
  @spec profile(module, host, Influx.profile()) :: {:ok, map} | Influx.error()
  def profile(adapter, host, profile \\ :all) do
    with {:ok, %{data: data}} <- adapter.profile(host, profile) do
      {:ok, data}
    end
  end

  @doc ~S"""
  See `profile/3`.
  """
  @spec profile!(module, host, Influx.profile()) :: map | no_return
  def profile!(adapter, host, profile \\ :all), do: bangify!(profile(adapter, host, profile))

  @spec query(module, URI.t() | String.t(), String.t(), Influx.Config.write_options()) ::
          {:ok, [map]} | Influx.error()
  def query(adapter, host, query, opts) do
    with {:ok, options} <- write_options(opts),
         {:ok, %{data: data}} <- adapter.query(host, query, options) do
      {:ok, data}
    end
  end

  @doc ~S"""
  See `query/4`.
  """
  @spec query!(module, URI.t() | String.t(), String.t(), Influx.Config.write_options()) ::
          :ok | no_return
  def query!(adapter, host, query, opts \\ []), do: bangify!(query(adapter, host, query, opts))

  @doc Influx.Docs.write()
  @spec write(module, URI.t() | String.t(), String.t(), Influx.Config.write_options()) ::
          :ok | Influx.error()
  def write(adapter, host, write, opts \\ []) do
    with {:ok, options} <- write_options(opts),
         {:ok, _response} <- adapter.write(host, write, options) do
      :ok
    end
  end

  @doc ~S"""
  See `write/4`.
  """
  @spec write!(module, URI.t() | String.t(), String.t(), Influx.Config.write_options()) ::
          :ok | no_return
  def write!(adapter, host, write, opts \\ []), do: bangify!(write(adapter, host, write, opts))

  def select(adapter, host, fields, opts) do
    query = "SELECT " <> prepare_fields(fields) <> " FROM #{opts[:from]}"
    opts = Keyword.delete(opts, :from)

    with {:ok, [%{result: result}]} <- query(adapter, host, query, opts),
         {:ok, %{columns: columns, values: values}} <- result do
      {:ok,
       Enum.map(
         values,
         fn row ->
           columns
           |> Enum.zip(row)
           |> Enum.into(%{})
           |> Map.update!("time", &NaiveDateTime.from_iso8601!/1)
         end
       )}
    end
  end

  defp prepare_fields(fields) when is_list(fields), do: Enum.join(fields, ",")
  defp prepare_fields(field), do: field
end
