# Agnus

Agnus is [Sunrise Sunset](https://sunrise-sunset.org) wrapped in an Elixir supervised GenServer.

- Self contained application when added as a dependency
- Simple configuration of lat, long and timezone of physical location of interest
- Caches the current day info to minimize calls to the API
- Returns a map of the data returned by the [Sunrise Sunset API](https://sunrise-sunset.org/api)

## Installation

Install the package by adding `agnus` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:agnus, "~> 0.1.0"}
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

## Basic Usage

See [Sunrise Sunset](https://sunrise-sunset.org) for details on the data available and what each key represents.

> At first glance the date times can be confusing since they represent the
> beginning and end of the phase of the visibility of the sun and the light
> we see.
>
> - For the time sun dims look at the `*_end` keys.
> - For the time when the sun shines look at the `*_begin` keys.
>
> This could be obvious to everyone however it took a moment of
> confusion for me to see the nuance.

```elixir
## Examples

# retrieve all available data for today
iex> Agnus.sun_info(:all)
%{
  astronomical_twilight_begin: #DateTime<2020-04-24 04:21:47-04:00 EDT America/New_York>,
  astronomical_twilight_end: #DateTime<2020-04-24 21:26:10-04:00 EDT America/New_York>,
  civil_twilight_begin: #DateTime<2020-04-24 05:34:11-04:00 EDT America/New_York>,
  civil_twilight_end: #DateTime<2020-04-24 20:13:46-04:00 EDT America/New_York>,
  day_length: 49311,
  nautical_twilight_begin: #DateTime<2020-04-24 04:59:10-04:00 EDT America/New_York>,
  nautical_twilight_end: #DateTime<2020-04-24 20:48:47-04:00 EDT America/New_York>,
  solar_noon: #DateTime<2020-04-24 12:53:58-04:00 EDT America/New_York>,
  sunrise: #DateTime<2020-04-24 06:03:03-04:00 EDT America/New_York>,
  sunset: #DateTime<2020-04-24 19:44:54-04:00 EDT America/New_York>
}

# retrieve a list of specific keys
iex> Agnus.sun_info([:civil_twilight_end, :civil_twilight_begin])
%{
  civil_twilight_begin: #DateTime<2020-04-24 05:34:11-04:00 EDT America/New_York>,
  civil_twilight_end: #DateTime<2020-04-24 20:13:46-04:00 EDT America/New_York>
}

# retrieve a single key
iex> Agnus.sun_info(:civil_twilight_end)
%{
  civil_twilight_end: #DateTime<2020-04-24 20:13:46-04:00 EDT America/New_York>}
}

# refresh data for today
iex> Agnus.trigger_sun_info_refresh()
:ok

```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/agnus](https://hexdocs.pm/agnus).
