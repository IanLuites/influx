defmodule Influx.Adapter do
  @moduledoc ~S"""
  Influx adapter.

  Can be implemented and set to allow for custom or more advanced connectors.
  """

  @callback ping(Influx.host()) :: Influx.result()
  @callback debug(Influx.host()) :: Influx.result()
  @callback requests(Influx.host(), pos_integer) :: Influx.result()
  @callback profile(Influx.host(), Influx.profile()) :: Influx.result()
  @callback write(Influx.host(), String.t(), Influx.write_options()) :: Influx.result()
  @callback query(Influx.host(), String.t(), Influx.write_options()) :: Influx.result()
end
