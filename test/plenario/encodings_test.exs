import Poison.Encoder, only: [encode: 2]

alias Plenario.Schemas.{
  VirtualDateField,
  VirtualPointField
}


defmodule Plenario.EncodingsTest do
  use Plenario.Testing.EtlCase

  test "encodings" do
    assert to_string(%{}) == "{}"
    assert to_string(%{foo: "bar"}) == "{\"foo\":\"bar\"}"
    assert encode({}, []) == "[]"
    assert encode({1, 2, 3}, []) == "[1,2,3]"
    assert encode(%VirtualDateField{}, []) == "{\"year_field\":null,\"second_field\":null,\"name\":null,\"month_field\":null,\"minute_field\":null,\"hour_field\":null,\"day_field\":null}"
    assert encode(%VirtualPointField{}, []) == "{\"name\":null,\"lon_field\":null,\"loc_field\":null,\"lat_field\":null}"
  end

  test "encoding schemas with associations" do

  end
end
