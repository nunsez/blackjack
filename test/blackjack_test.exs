defmodule BlackjackTest do
  use ExUnit.Case, async: true
  doctest Blackjack

  test "greets the world" do
    assert Blackjack.hello() == :world
  end
end
