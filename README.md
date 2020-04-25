# Agnus

Agnus is [Sunrise Sunset](https://sunrise-sunset.org) wrapped in an Elixir supervised GenServer.

* Self contained application when added as a dependency
* Simple configuration of lat, long and timezone of physical location of interest
* Caches the current day info to minimize calls to the API
* Returns a map of the data returned by the [Sunrise Sunset API](https://sunrise-sunset.org/api)


## Installation

Install the package by adding `agnus` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:agnus, "~> 0.0.2"}
  ]
end
```

## Configuration

```elixir
# Defaults if not overridden by local configuration
config :agnus,
  day_info: [
    # should the GenServer init() and/or init args be logged?
    log: [init: false, init_args: false],
    # timezone of interest
    tz: "America/New_York",
    api: [
      # url of the API (shouldn't need to be changed)
      url: "https://api.sunrise-sunset.org",
      # latitude in decimal degrees
      lat: 40.2108,
      # longitude in decimal degrees
      lng: -74.011
  ]
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/agnus](https://hexdocs.pm/agnus).
