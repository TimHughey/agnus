defmodule Agnus.Types do
  @moduledoc """
  Public API types

  """

  @type cache_file :: binary() | :none
  @type daylength :: pos_integer()

  @type opts_map ::
          %{
            api: %{
              lat: float(),
              lng: float(),
              url: binary(),
              fetcher: Agnus.Fetcher | module(),
              timeout: integer(),
              recv_timeout: integer()
            },
            tz: binary(),
            cache_file: cache_file(),
            timeout: binary(),
            log: %{
              init: boolean(),
              init_args: boolean(),
              cache_failures: boolean()
            }
          }

  @type suninfo :: false | DateTime.t() | daylength()

  @type suninfo_key ::
          :sunrise
          | :sunset
          | :solar_noon
          | :day_length
          | :civil_twilight_begin
          | :civil_twilight_end
          | :nautical_twilight_begin
          | :nautical_twilight_end
          | :astronomical_twilight_begin
          | :astronomical_twilight_end

  @type suninfo_request :: :all | suninfo_key | [suninfo_key]
  @type suninfo_response ::
          false | %DateTime{} | %{optional(suninfo_key()) => suninfo()}

  @type trigger_opts :: none() | [] | [force: boolean()]
end
