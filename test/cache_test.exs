defmodule CacheTest do
  @moduledoc false

  use ExUnit.Case
  @moduletag :cache

  test "can save document body" do
    body = """
    Agnus Cache Test Body
    """

    body_len = String.length(body)

    tmp_dir = System.tmp_dir()

    refute is_nil(tmp_dir)

    cf = Path.join([tmp_dir, "agnus-test.json"])
    state = %{body: body, opts: %{cache_file: cf, log: %{}}}
    returned_state = Agnus.Cache.save_if_needed(state)

    assert state == returned_state

    {rc, info} = File.stat(cf)

    assert :ok == rc

    %File.Stat{size: on_disk_size} = info
    assert body_len == on_disk_size

    assert {:ok, [cf]} == File.rm_rf(cf)
  end

  test "can switch cache json settings" do
    tmp_dir = System.tmp_dir()
    file = Path.join(tmp_dir, "agnus-cache-switch.json")

    log = [:opts, :log, :cache_failures]
    cache = [:opts, :cache_file]
    body = "Agnus Json Document Body"

    s =
      :sys.get_state(Agnus.Server)
      |> put_in(log, true)
      |> put_in(cache, file)
      |> put_in([:body], body)

    Agnus.Cache.save_if_needed(s)

    assert File.exists?(file)
    assert :ok == File.chmod(file, 0o000)

    # implictly test logging of cache read / write failure (permission denied)
    Agnus.Cache.load_if_possible(s) |> Agnus.Cache.save_if_needed()

    # indirectly test parse failure
    s = Map.drop(s, [:body])
    assert :ok == File.chmod(file, 0o600)

    rs =
      Agnus.Cache.load_if_possible(s)
      |> Agnus.Parser.decode()
      |> Agnus.Server.finalize_dayinfo()
      |> Agnus.Cache.save_if_needed()

    {rc, _} = get_in(rs, [:dayinfo, :error])
    assert :error == rc

    # test existing cache file is removed
    msg = {:action, :cache_file, :none}
    {_, rc, rs, _} = Agnus.Server.handle_call(msg, nil, s)
    assert rc == :none
    assert :none == rs.opts.cache_file
    refute File.exists?(file)

    File.rm_rf(file)
  end

  test "can enable and disable json cache" do
    tmp_dir = System.tmp_dir()
    refute is_nil(tmp_dir)

    cf = Path.join([tmp_dir, "agnus.json"])
    File.rm(cf)

    Agnus.cache_json(cf)

    # wait for file to be created because a cast message is sent to
    # force a refresh
    wait_for_file = fn ->
      for _k <- 1..2000, reduce: false do
        true ->
          true

        false ->
          Process.sleep(1)
          Agnus.current?() and File.exists?(cf)
      end
    end

    assert wait_for_file.()

    # disable the cache
    Agnus.cache_json(:none)

    refute File.exists?(cf)
  end
end
