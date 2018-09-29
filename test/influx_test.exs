defmodule InfluxTest do
  use ExUnit.Case
  doctest Influx

  test "greets the world" do
    assert Influx.hello() == :world
  end
end
