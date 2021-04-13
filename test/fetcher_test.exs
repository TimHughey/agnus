defmodule FetcherTest do
  @moduledoc false

  # async: false due to state manipulations
  use ExUnit.Case, async: true
  @moduletag :fetcher

  # all tests will use an invalid API url to minimize calls to actual API
  setup context do
    %{opts: %{api: api}} = s = :sys.get_state(Agnus.Fetcher)
    s = Map.drop(s, [:reply_to])

    api = Map.merge(api, %{url: "notarealname.com", timeout: 1, recv_timeout: 1})

    put_in(context, [:state], put_in(s, [:opts, :api], api))
  end

  test "can fetch_json/1 handle invalid api https urls", ctx do
    ns = Agnus.Fetcher.fetch_json(ctx.state)

    assert get_in(ns, [:error]),
           "fetch_json/1 should add :error to state #{inspect(ns, pretty: true)}"
  end

  test "can fetch_json_reschedule_if_needed/1 detect a previous error", ctx do
    ns = Agnus.Fetcher.fetch_json(ctx.state) |> Agnus.Fetcher.fetch_json_reschedule_if_needed()

    refute get_in(ns, [:error]),
           "fetch_json_reschedule_if_needed/1 should have removed :error key"
  end

  test "can fetch_if_needed/1 reschedule the fetch after the timeout has expired", ctx do
    s = get_in(ctx, [:state])
    lf = get_in(s, [:last_fetch]) |> Timex.shift(minutes: -5)

    s = put_in(s, [:last_fetch], lf)

    ns = Agnus.Fetcher.fetch_if_needed(s)

    refute get_in(ns, [:body]),
           "fetch_if_needed/1 should have attempted to fetch:\n#{inspect(ns, pretty: true)}"
  end
end
