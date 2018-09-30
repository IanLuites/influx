defmodule Influx.Config do
  @moduledoc false
  alias Influx.Error

  @doc ~S"""
  Parse write options.
  """
  @spec write_options(Influx.write_options(), map) :: {:ok, map} | {:error, Error.t()}
  def write_options(options, opts \\ %{})

  def write_options([], opts) do
    if opts[:db],
      do: {:ok, opts},
      else: {:error, %Error{message: "No database for writing given. (required)"}}
  end

  def write_options([{option, value} | options], opts) do
    case validate_write_options(option, value) do
      {:ok, name, value} -> write_options(options, Map.put(opts, name, value))
      error = {:error, _} -> error
    end
  end

  @spec validate_write_options(Influx.write_option(), term) ::
          {:ok, Influx.write_option(), term} | {:error, Error.t()}
  defp validate_write_options(option, value)

  # Consistency
  defp validate_write_options(:consistency, value) when value in ~w(any one quorum all)a,
    do: {:ok, :consistency, value}

  defp validate_write_options(:consistency, v),
    do: {:error, %Error{message: ~s(Invalid consistency given: #{inspect(v)})}}

  # Consistency
  defp validate_write_options(:precision, :nanosecond), do: {:ok, :precision, :ns}
  defp validate_write_options(:precision, :microsecond), do: {:ok, :precision, :u}
  defp validate_write_options(:precision, :millisecond), do: {:ok, :precision, :ms}
  defp validate_write_options(:precision, :second), do: {:ok, :precision, :s}
  defp validate_write_options(:precision, :minute), do: {:ok, :precision, :m}
  defp validate_write_options(:precision, :hour), do: {:ok, :precision, :h}

  defp validate_write_options(:precision, v),
    do: {:error, %Error{message: ~s(Invalid precision given: #{inspect(v)})}}

  # Database
  defp validate_write_options(:db, value) when is_binary(value), do: {:ok, :db, value}

  defp validate_write_options(:db, v),
    do: {:error, %Error{message: ~s(Invalid database given: #{inspect(v)})}}

  defp validate_write_options(:database, value), do: validate_write_options(:db, value)

  # Username
  defp validate_write_options(:username, value) when is_binary(value), do: {:ok, :u, value}

  defp validate_write_options(:username, v),
    do: {:error, %Error{message: ~s(Invalid username given: #{inspect(v)})}}

  defp validate_write_options(:u, value), do: validate_write_options(:username, value)

  # Password
  defp validate_write_options(:password, value) when is_binary(value), do: {:ok, :p, value}

  defp validate_write_options(:password, v),
    do: {:error, %Error{message: ~s(Invalid password given: #{inspect(v)})}}

  defp validate_write_options(:p, value), do: validate_write_options(:password, value)

  # Retention Policy Name
  defp validate_write_options(:retention_policy, value) when is_binary(value),
    do: {:ok, :rp, value}

  defp validate_write_options(:retention_policy, v),
    do: {:error, %Error{message: ~s(Invalid retention policy given: #{inspect(v)})}}

  defp validate_write_options(:rp, value), do: validate_write_options(:retention_policy, value)

  # Fallback
  defp validate_write_options(option, _),
    do: {:error, %Error{message: ~s(Unknown write option given: #{inspect(option)})}}
end
