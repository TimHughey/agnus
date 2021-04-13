defmodule ServerTest do
  @moduledoc false

  require Logger
  use Timex

  # async: false due to state manipulations
  use ExUnit.Case, async: false

  @moduletag :server

  test "can server fetch data for today" do
    wait_for_last_fetch = fn ->
      for _x <- 1..2000, reduce: false do
        false ->
          Process.sleep(1)
          Agnus.Server.get_info(:last_fetch)

        %DateTime{} = lf ->
          tz = "America/New_York"
          lf = Timex.to_datetime(lf, tz)
          now = Timex.now(tz)

          Timex.day(now) == Timex.day(lf)

        true ->
          true
      end
    end

    assert wait_for_last_fetch.(), "server last fetch != today after 1000ms"
  end

  test "can serve handle get request when data is out of date" do
    s = :sys.get_state(Agnus.Server) |> put_in([:dayinfo, :latest], nil)
    msg = {:action, :get, nil}

    {reply, rc, next_state, _timeout} = Agnus.Server.handle_call(msg, nil, s)

    assert :reply == reply, "handle_call/3 tuple should include :reply"
    assert rc == false, "handle_call/3 should return false"
    pending = get_in(next_state, [:fetch_pending])

    assert pending, "server should request fetch when data is not available"
  end

  test "can server process a timeout (scheduled refresh)" do
    state = :sys.get_state(Agnus.Server)

    {_, %{last_timeout: first} = state, _} = Agnus.Server.handle_info(:timeout, state)

    {_, %{last_timeout: second}, _} = Agnus.Server.handle_info(:timeout, state)

    assert DateTime.diff(second, first, :nanosecond) > 0
  end

  test "can server handle unavailable Fetcher GenServer" do
    s =
      :sys.get_state(Agnus.Server)
      |> put_in([:opts, :api, :fetcher], nil)
      |> Map.drop([:parsed, :fetch_pending])

    ns = Agnus.Server.fetch_if_needed(s)

    refute get_in(ns, [:fetch_pending]), "fetch_if_needed/1 should not have set fetch_pending"
  end

  test "can server handle receipt of a suprious recv fetched data msg" do
    # ensure :pending_fetch is not in the state
    s = :sys.get_state(Agnus.Server) |> Map.drop([:pending_fetch])

    msg = {:action, :fetched_data, %{}}
    {rc, _ns, _timeout} = Agnus.Server.handle_cast(msg, s)

    # this is a specific code path test, just check for :noreply
    assert :noreply == rc
  end

  test "can server ignore additional fetch requests when a fetch is pending" do
    s = :sys.get_state(Agnus.Server) |> put_in([:fetch_pending], true)

    msg = {:action, :day_refresh, nil}
    {:noreply, ns, _timeout} = Agnus.Server.handle_cast(msg, s)

    msg_txt = "handle_cast/2 should not have changed:\n"

    assert Map.equal?(s, ns),
           "#{msg_txt}\nstate:\n#{inspect(s, pretty: true)}\nchanged:\n#{
             inspect(ns, pretty: true)
           }"

    msg_txt = "fetch_if_needed/1 should not have changed:\n"
    ns = Agnus.Server.fetch_if_needed(s)

    assert Map.equal?(s, ns),
           "#{msg_txt}\nstate:\n#{inspect(s, pretty: true)}\nchanged:\n#{
             inspect(ns, pretty: true)
           }"
  end

  test "can server handle bad GenServer.call/2" do
    assert {:bad_call, :bad} == GenServer.call(Agnus.Server, :bad)
  end

  test "can server handle bad GenServer.cast/2" do
    Logger.put_module_level(Agnus.Server, :info)
    assert :ok == GenServer.cast(Agnus.Server, :bad)
  end

  test "can server log? handle unknown keys" do
    assert Agnus.Server.log?(%{opts: %{log: %{}}}, :not_a_key)
  end

  test "can server terminate/2 log terminate reason" do
    # implicit logging test
    Agnus.Server.terminate(:ill_be_back, %{opts: %{log: %{init: true}}})
  end
end
