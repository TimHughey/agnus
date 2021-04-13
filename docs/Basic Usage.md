## Basic Usage

Like most tech types I like examples so that is where we'll start.

### Examples

```elixir
# check if the sun info is current
iex> Agnus.current?()
true

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
#DateTime<2020-04-24 20:13:46-04:00 EDT America/New_York>}

# refresh data for today
iex> Agnus.trigger_sun_info_refresh()
:ok
```

### Sunrise Sunset Twilight

The datetime values returned are calculated by [Sunrise Sunset](https://sunrise-sunset.org).
At that link you will find a detailed description of the exact instant each
datetime represents.

### Typical Operation

Overall Agnus is designed to operate in the background and require nothing more
than the [configuration](this-is-agnus.html#configuration).

Agnus is comprised of two GenServers. The first is the backend for the public
api and quickly returns cached sun information. The second is responsible for
fetching the information for the current day.

At startup, Agnus will fetch the sun information for the current day and cache
the data. Requests for data via the public API are serviced by the caching
GenServer. Subsequent sun information fetches are handled by the second GenServer.

This design ensures requests for data never _wait_ due to a pending data fetch.

The downside, however, is a brief (~100ms) period each day (midnight, local time)
when a data race can occur. During this period calls to the public API will
return `false` indicating the request should be retried.

The above is also true if [Sunrise Sunset](https://sunrise-sunset.org) is unreachable
or some other network disruption is occurring.
