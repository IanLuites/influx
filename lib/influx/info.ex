defmodule Influx.Info do
  @moduledoc ~S"""

  """

  @typedoc @moduledoc
  @type t :: %__MODULE__{version: Version.t(), build: :open_source | :enterprise}

  @enforce_keys [:version, :build]
  defstruct @enforce_keys
end
