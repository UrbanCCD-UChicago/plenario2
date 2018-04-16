defmodule Plenario.ApplicationTest do
  use ExUnit.Case, async: true

  test "config_change returns :ok" do
    assert Plenario.Application.config_change([], [], []) == :ok
  end
end
