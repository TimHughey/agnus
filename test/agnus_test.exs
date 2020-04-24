defmodule AgnusTest do
  use ExUnit.Case
  doctest Agnus

  test "greets the world" do
    assert Agnus.hello() == :world
  end
end
