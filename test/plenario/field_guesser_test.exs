defmodule Plenario.FieldGuesserTest do
  use ExUnit.Case

  import Plenario.FieldGuesser

  test "guess/1" do
    assert guess("true") == "boolean"
    assert guess("7") == "integer"
    assert guess("0.0") == "float"
    assert guess("01/01/2000") == "timestamptz"
    assert guess(~s/{"foo": "bar"}/) == "jsonb"
  end

  test "boolean?/1" do
    assert boolean?(true)
    assert boolean?(false)
    assert boolean?("true")
    assert boolean?("false")
    assert boolean?("t")
    assert boolean?("f")
  end

  test "integer?/1" do
    assert integer?(0)
    assert integer?(0.0) == false
    assert integer?("7")
    assert integer?("9.0") == false
  end

  test "float?/1" do
    assert float?(0) == false
    assert float?(0.0)
    assert float?("0") == false
    assert float?("0.0")
  end

  test "date?/1" do
    assert date?("01/01/2000")
    assert date?("01/01/2000 01:01:01 AM")
    assert date?("01/01/2000 01:01:01 PM")
    assert date?("01-01-2000")
    assert date?("01-01-2000 01:01:01 PM")
    assert date?("01-01-2000 01:01:01 PM")
    assert date?("2000-01-01 01:01:01")
    assert date?("2000-01-01 01:01:01.0000")

    assert date?("09-01749218") == false
    assert date?("09017492-18") == false
    assert date?("0901749218") == false
    assert date?("(000) 000-0000") == false
  end

  test "json?/1" do
    assert json?("{}")
    assert json?("[]")
    assert json?(~s/{"foo": "bar"}/)
    assert json?(~s/{"foo": {"bar": "baz"}}/)
    assert json?(~s/[{"foo": {"bar": "baz"}}]/)
  end
end