defmodule Influx.Docs do
  @moduledoc false

  @influx_version "v1.6"

  @doc false
  @spec influx :: String.t()
  def influx,
    do: """
    InfluxDB driver.

    ## Quick Setup

    ```elixir
    # In your config/config.exs file
    config :my_app, Sample.InfluxDB,
      url: "http://localhost:8086",
      database: "example_db"

    # In your application code
    defmodule Sample.InfluxDB do
      @moduledoc ~S"My InfluxDB instance."
      use Influx,
        otp_app: :my_app,
        adapter: Influx.Adapters.HTTPX # Optional, HTTPX is default.
    end

    defmodule Sample.App do
      alias Sample.InfluxDB

      def log do
        InfluxDB.query!("CREATE DATABASE example_db")
        InfluxDB.write!("mymeas,mytag=1 myfield=90 1463683075", precision: :second)
      end
    end
    ```

    ## Installation

    The package can be installed by adding `influx`
    to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [
        {:influx, "~> 0.0.1"}
      ]
    end
    ```
    """

  @doc false
  @spec write :: String.t()
  def write,
    do: """
    Use this to write data to a pre-existing database.

    It is recommend to write points in batches of 5,000 to 10,000 points.
    Smaller batches, and more requests, will result in sub-optimal performance.

    ## Options
    ### Database
    _(Required)_

    ```
    database: String.t
    ```

    Sets the target [database](https://docs.influxdata.com/influxdb/#{@influx_version}/concepts/glossary/#database) for the write.

    The database can only be set in the configuration.

    ### Username
    _(Optional, if you haven’t [enabled authentication](https://docs.influxdata.com/influxdb/#{
      @influx_version
    }/administration/authentication_and_authorization/#set-up-authentication). Required if you’ve enabled authentication.)_

    ```
    username: String.t
    ```

    Sets the username for authentication if you’ve enabled authentication.
    The user must have write access to the database.
    Use with the `password:` option.

    The username can also be passed in the `url:` config.

    ### Password
    _(Optional, if you haven’t [enabled authentication](https://docs.influxdata.com/influxdb/#{
      @influx_version
    }/administration/authentication_and_authorization/#set-up-authentication). Required if you’ve enabled authentication.)_

    ```
    password: String.t
    ```

    Sets the password for authentication if you’ve enabled authentication.
    Use with the `username:` option.

    The password can also be passed in the `url:` config.

    ### Consistency
    _(Optional, available with [InfluxDB Enterprise clusters](https://docs.influxdata.com/enterprise_influxdb/#{
      @influx_version
    }/) only.)_

    ```
    consistency: :any | :one | :quorum | :all
    ```

    Sets the write consistency for the point.
    InfluxDB assumes that the write consistency is `:one` if you do not specify `consistency:`.
    See the [InfluxDB Enterprise documentation](https://docs.influxdata.com/enterprise_influxdb/#{
      @influx_version
    }/concepts/clustering#write-consistency) for detailed descriptions of each consistency option.

    ### Precision
    _(Optional)_

    ```
    precision: :nanosecond | :microsecond | :millisecond | :second | :minute | :hour
    ```

    Sets the precision for the supplied Unix time values.
    InfluxDB assumes that timestamps are in nanoseconds if you do not specify precision.

    We recommend using the least precise precision possible as this can result in significant improvements in compression.

    ### Retention Policy Name
    _(Optional)_

    ```
    retention_policy: String.t
    ```

    Sets the target [retention policy](https://docs.influxdata.com/influxdb/#{@influx_version}/concepts/glossary/#retention-policy-rp) for the write.
    InfluxDB writes to the `DEFAULT` retention policy if you do not specify a retention policy.

    ## Examples
    ### Write a point to the database `mydb` with a timestamp in seconds

    ```elixir
    iex> write("mymeas,mytag=1 myfield=90 1463683075", database: "mydb", precision: :second)
    :ok
    ```

    ### Write a point to the database `mydb` and the retention policy `myrp`

    ```elixir
    iex> write("mymeas,mytag=1 myfield=90", database: "mydb", retention_policy: "myrp")
    :ok
    ```

    ### Writing to a secured InfluxDB

    Correct credentials:
    ```elixir
    iex> write("mymeas,mytag=1 myfield=91", database: "mydb", username: "myuser", password: "mypassword")
    :ok
    ```

    Invalid credentials:

    ```elixir
    iex> write("mymeas,mytag=1 myfield=91", database: "mydb", username: "myuser", password: "notmypassword")
    {:error, %Influx.Error{message: "authorization failed"}}
    ```
    """

  @doc false
  @spec ping :: String.t()
  def ping,
    do: ~S"""
    Ping the Influx server to check the connections settings and
    confirm your InfluxDB instance is up and running.

    ## Examples

    ```elixir
    iex> ping()
    :ok
    ```
    """

  @doc false
  @spec info :: String.t()
  def info,
    do: ~S"""
    Fetch the build and version of an InfluxDB instance.

    The build can either be the `:open_source` or `:enterprise` version.

    ## Examples

    ```elixir
    iex> info()
    {:ok, %Influx.Info{build: :open_source, version: #Version<1.6.3>}}
    ```
    """

  @doc false
  @spec debug :: String.t()
  def debug,
    do: ~S"""
    InfluxDB exposes statistics and information about its runtime.

    Optionally pass a specific field as atom or for nested values a list of atoms.

    > Note:
    > The [InfluxDB input plugin](https://github.com/influxdata/telegraf/tree/release-1.7/plugins/inputs/influxdb)
    > is available to collect metrics (using the `/debug/vars` endpoint) from specified Kapacitor instances.
    >
    > For a list of the measurements and fields, see the [InfluxDB input plugin README](https://github.com/influxdata/telegraf/tree/release-1.7/plugins/inputs/influxdb).

    ## Examples

    ### Getting all debug information
    ```elixir
    iex> debug()
    {:ok, %{cmdline: ["influxd"], ...}}
    ```

    ### Getting specific debug information
    ```elixir
    iex> debug(:cmdline)
    {:ok, ["influxd"]}
    ```

    ### Getting nested debug information
    ```elixir
    iex> debug([:memstats, :Alloc])
    {:ok, 38566248}
    ```
    """

  @doc false
  @spec requests :: String.t()
  def requests,
    do: ~S"""
    Track the number of writes and queries to InfluxDB per username and IP address.

    Optionally pass the amount of seconds to track writes and queries.
    (Defaults to 10s.)

    ## Examples

    ### Track requests over a ten-second interval
    ```elixir
    iex> requests()
    {:ok, %{"user1:123.45.678.91" => %{writes: 1, queries: 0}}}
    ```
    The response shows that, over the past ten seconds,
    the `user1` user sent one request to the `write` and
    no requests to `query` from the `123.45.678.91` IP address.


    ### Track requests over a one-minute interval
    ```elixir
    iex> requests(60)
    {:ok, %{
      "user1:123.45.678.91" => %{writes: 3, queries: 0},
      "user1:000.0.0.0" => %{writes: 0, queries: 16},
      "user2:xx.xx.xxx.xxx" => %{writes: 4, queries: 0}
    }}
    ```
    The response shows that, over the past minute,
    `user1` sent three requests to `write` from `123.45.678.91`,
    `user1` sent 16 requests to `query` from `000.0.0.0`,
    and `user2` sent four requests to `write` from `xx.xx.xxx.xxx`.
    """

  @doc false
  @spec profile :: String.t()
  def profile,
    do: ~S"""
    InfluxDB supports the Go [`net/http/pprof`](https://golang.org/pkg/net/http/pprof/)
    format, which is useful for troubleshooting.
    The pprof package serves runtime profiling data
    in the format expected by the pprof visualization tool.

    ## Profiles

    It is possible to pass a profile for debugging.
    Default is `:all`.

    | **Profile**     | **Description**                                                  |
    |-----------------|------------------------------------------------------------------|
    | `:all`          | All stack traces.                                                |
    | `:block`        | Stack traces that led to blocking on synchronization primitives. |
    | `:goroutine`    | Stack traces of all current goroutines.                          |
    | `:heap`         | Sampling of stack traces for heap allocations.                   |
    | `:mutex`        | Stack traces of holders of contended mutexes.                    |
    | `:threadcreate` | Stack traces that led to the creation of new OS threads.         |
    """

  @doc false
  @spec generate_readme! :: :ok | no_return
  def generate_readme! do
    func_doc =
      Enum.map(
        ~w(write ping info debug requests profile)a,
        &"""
        ## #{String.capitalize(to_string(&1))}

        #{String.replace(:erlang.apply(__MODULE__, &1, []), "\n#", "\n##")}
        """
      )

    File.write!(
      "README.md",
      :erlang.iolist_to_binary([
        "# Influx",
        "\n\n",
        influx(),
        func_doc
      ])
    )
  end
end
