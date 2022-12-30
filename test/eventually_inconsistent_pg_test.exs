defmodule EventuallyInconsistentPgTest do
  use ExUnit.Case
  doctest EventuallyInconsistentPg

  test "greets the world" do
    assert EventuallyInconsistentPg.hello() == :world
  end
end
