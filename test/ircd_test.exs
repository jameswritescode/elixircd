defmodule IRCdTest do
  use ExUnit.Case
  doctest IRCd

  test "greets the world" do
    assert IRCd.hello() == :world
  end
end
