defmodule AgnusTest do
  @moduledoc false

  # use Timex

  use ExUnit.Case, async: false
  @moduletag :public_api

  test "can start server" do
    pid = GenServer.whereis(Agnus.Server)

    assert is_pid(pid)
  end

  test "can get current data" do
    # perform all tests that require current data in a specific order

    wait_for_current = fn ->
      for _x <- 1..1000, reduce: false do
        false ->
          Process.sleep(1)
          Agnus.current?()

        true ->
          true
      end
    end

    # wait up to 100ms for the server to get current data
    assert wait_for_current.()

    keys = Agnus.keys()
    key_count = Enum.count(keys)

    assert is_list(keys), "Agnus.keys() should return a list"
    assert :sunrise in keys, "Agnus.keys() should return :sunrise"
    assert 10 == key_count, "Agnus.keys() count #{inspect(key_count)} != 11"

    all = Agnus.sun_info()

    assert is_map(all), "Agnus.sun_info() should return a map: #{inspect(all, pretty: true)}"
    assert is_struct(get_in(all, [:sunset])), "Agnus.sun_info() should return a %DateTime()"
    assert 10 == Enum.count(all), "Agnus.sun_info() count should be 11"

    noon = Agnus.noon()
    assert %DateTime{} = noon, "Agnus.noon() should be a %DateTime{}"

    sunset = Agnus.sunset()
    assert %DateTime{} = sunset, "Agnus.sunset() should be a %DateTime{}"

    sunrise = Agnus.sunrise()
    assert %DateTime{} = sunrise, "Agnus.sunrise() should be a %DateTime{}"

    assert :ok == Agnus.trigger_refresh()
    assert :ok == Agnus.trigger_refresh([])
    assert :ok == Agnus.trigger_refresh(force: true)

    assert wait_for_current.()

    assert :ok == Agnus.trigger_refresh()

    key_list = [:sunrise, :sunset]
    info = Agnus.get_info([:sunrise, :sunset])

    txt = inspect(key_list)
    msg = "Agnus.get_info(#{txt}) should"
    assert is_map(info), "#{msg} return a map: #{inspect(info, pretty: true)}"

    for key <- key_list do
      ktxt = inspect(key)
      dt = get_in(info, [key])
      assert dt, "#{msg} should contain #{ktxt}"
      assert %DateTime{} = dt, "#{msg} key=#{ktxt} should be a %DateTime{}"
    end

    rc = Agnus.cache_json()
    msg = "Agnus.cache_json/0 (:query) should"
    assert is_binary(rc) or rc == :none, "#{msg} return :none or a binary: #{inspect(rc)}"
  end
end
