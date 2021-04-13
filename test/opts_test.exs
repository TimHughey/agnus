defmodule OptsTest do
  @moduledoc false

  use ExUnit.Case, async: false
  @moduletag :opts

  test "can merge_opts/2 detect default opts" do
    fake_state = Agnus.Opts.merge_args(%{}, [])

    assert fake_state.opts.defaults
  end

  test "can merge_opts/2 handle provided args" do
    args = [opts: [log_init: true]]

    fake_state = Agnus.Opts.merge_args(%{}, args)

    refute get_in(fake_state, [:opts, :defaults])
  end
end
