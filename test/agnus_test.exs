defmodule AgnusTest do
  use ExUnit.Case
  doctest Agnus

  test "server started" do
    pid = GenServer.whereis(Agnus.DayInfo)

    assert is_pid(pid)
  end
end
