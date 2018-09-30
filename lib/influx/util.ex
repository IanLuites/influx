defmodule Influx.Util do
  @moduledoc false

  @doc false
  defmacro bangify!(call) do
    quote do
      case unquote(call) do
        :ok -> :ok
        {:ok, result} -> result
        {:error, err = %Influx.Error{}} -> raise err
        {:error, atom} -> raise %Influx.Error{message: to_string(atom)}
      end
    end
  end

  @doc false
  @spec safe_in(map, atom | list) :: term
  def safe_in(map, field) when is_atom(field), do: Map.get(map, field)
  def safe_in(map, []), do: map
  def safe_in(map, getter), do: get_in(map, getter)
end
