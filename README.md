## This is Agnus

[![Hex.pm Version](http://img.shields.io/hexpm/v/agnus.svg?style=flat)](https://hex.pm/packages/agnus)
[![Coverage Status](https://coveralls.io/repos/github/TimHughey/agnus/badge.svg?branch=master)](https://coveralls.io/github/TimHughey/agnus?branch=master)

Agnus is [Sunrise Sunset](https://sunrise-sunset.org) wrapped in an Elixir supervised GenServer.

- Self contained application when added as a dependency
- Simple configuration of lat, long and timezone of physical location of interest
- Caches (within the GenServer state) the current day info to minimize calls to the API
- Returns a map of the data returned by the [Sunrise Sunset API](https://sunrise-sunset.org/api)

### Installation

Install the package by adding `agnus` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:agnus, "~> 0.1.1"}
  ]
end
```

### Configuration

Agnus includes a default configuration that, unless you live at the author's
home, should be adjusted.

The most common and only configuration items required are:

1. Timezone (reference for date/times returned)
2. Latitude and Longitude

### Recommended Configuration

```elixir
config :agnus,
  day_info: [
    # timezone of interest
    tz: "Australia/Sydney",
    api: [
      # latitude in decimal degrees
      lat: -33.865143,
      # longitude in decimal degrees
      lng: 151.2099,
    ]
  ]
```

#### Defaults

The configuration in your application will be deeply merged with the defaults.

```elixir
# Defaults when not overridden within the global application environment
config :agnus,
  day_info: [
    # timezone of interest
    tz: "America/New_York",
    # sunrise sunset API and related parameters
    api: [
      # latitude in decimal degrees
      lat: 40.2108,
      # longitude in decimal degrees
      lng: -74.011,
      # url of the API (shouldn't need to be changed)
      url: "https://api.sunrise-sunset.org",
      # module that performs the actual data fetches
      # do not change this unless you implement one to replace it
      fetcher: Agnus.Fetcher,
      # HTTPoision get timeout in milliseconds (initial connection)
      timeout: 500,
      # HTTPoision get receive timeout in milliseconds
      recv_timeout: 500
    ],
    # file to store the raw JSON response from the sunrise sunset api, if desired.
    # options are :none or a binary file path (see Configuration Options)
    cache_file: :none,
    # how frequently, as a RFC8601 duration, should the server wakeup to check
    # if the locally cached sun info is `Agnus.current?/0`
    #
    # this setting is implemented as a GenServer timeout and is only relevant
    # when the Agnus API is invoked infrequently.
    timeout: "PT1M",
    # should the server init(), init args and cache failures be logged?
    log: [init: false, init_args: false, cache_failures: false],
  ]
```

> I am aware the use of the global application environment is discouraged
> by the Elixir Library Guidelines. I would argue it is acceptable for Agnus
> due to the nature of the data returned (e.g. date/time of sun positions
> at a specific location on the planet).
