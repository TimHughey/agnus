defmodule ParserTest do
  @moduledoc false

  # async: false due to state manipulations
  use ExUnit.Case, async: true
  @moduletag :parser

  test "can parser ignore unwanted keys" do
    json = """
    {"results":
      {"sunrise":"2021-04-10T10:22:21+00:00",
       "sunset":"2021-04-10T23:31:20+00:00",
       "solar_noon":"2021-04-10T16:56:50+00:00",
       "day_length":47339,
       "civil_twilight_begin":"2021-04-10T09:54:28+00:00",
       "civil_twilight_end":"2021-04-10T23:59:12+00:00",
       "nautical_twilight_begin":"2021-04-10T09:21:05+00:00",
       "nautical_twilight_end":"2021-04-12T00:32:36+00:00",
       "astronomical_twilight_begin":"2021-04-10T08:46:11+00:00",
       "astronomical_twilight_end":"2021-04-12T01:07:30+00:00",
       "ignore_key": true},
      "status":"OK"}
    """

    s = :sys.get_state(Agnus.Server) |> put_in([:body], json)

    # implicit test
    Agnus.Parser.decode(s)

    assert true
  end

  test "can parser detect stale data" do
    json = """
    {"results":
      {"sunrise":"2021-04-10T10:22:21+00:00",
       "sunset":"2021-04-10T23:31:20+00:00",
       "solar_noon":"2021-04-10T16:56:50+00:00",
       "day_length":47339,
       "civil_twilight_begin":"2021-04-10T09:54:28+00:00",
       "civil_twilight_end":"2021-04-10T23:59:12+00:00",
       "nautical_twilight_begin":"2021-04-10T09:21:05+00:00",
       "nautical_twilight_end":"2021-04-12T00:32:36+00:00",
       "astronomical_twilight_begin":"2021-04-10T08:46:11+00:00",
       "astronomical_twilight_end":"2021-04-12T01:07:30+00:00"},
      "status":"OK"}
    """

    s = :sys.get_state(Agnus.Server) |> put_in([:body], json)

    state = Agnus.Parser.decode(s)

    assert get_in(state, [:need_fetch]) == true
  end
end
