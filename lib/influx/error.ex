defmodule Influx.Error do
  @enforce_keys [:message]
  defexception [:message, :id]
end
