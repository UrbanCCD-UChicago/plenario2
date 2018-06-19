defmodule Plenario.Encodings.Helpers do
  import Plenario.Actions.DataSetFieldActions, only: [field_names: 1]

  def field_name_map(field, atoms) do
    field_kwlist = Enum.map(atoms, fn atom -> {atom, Map.get(field, atom)} end)
    null_fields = Enum.filter(field_kwlist, fn {_atom, id} -> is_nil(id) end)

    non_null_field_names =
      Enum.filter(field_kwlist, fn {_atom, id} -> not is_nil(id) end)
      |> Enum.map(fn {_, id} -> id end)
      |> field_names()

    non_null_fields =
      Enum.filter(field_kwlist, fn {_atom, id} -> not is_nil(id) end)
      |> Enum.map(fn {atom, _} -> atom end)
      |> Enum.zip(non_null_field_names)

    null_fields ++ non_null_fields
    |> Enum.map(fn {atom, field_name} ->
      atom = Atom.to_string(atom)
      |> String.replace_suffix("_id", "")
      |> String.to_atom()
      {atom, field_name}
    end)
    |> Map.new()
  end
end

alias Plenario.Schemas.{
  VirtualDateField,
  VirtualPointField
}


defimpl String.Chars, for: Map do

  @doc """
  Implementation of String.Chars behaviour for maps to make serialization
  more straightforward.

  ## Examples

      iex> to_string(%{})
      "{}"

      iex> to_string(%{foo: "bar"})
      "{\"foo\":\"bar\"}"

  """
  def to_string(map) when is_map(map) do
    Poison.encode!(map)
  end
end


defimpl Poison.Encoder, for: Tuple do

  @doc """
  Implementation of JSON encoding behaviour for tuples to make serialization
  more straightforward. Converts Elixir tuples to JSON lists.

  ## Examples

      iex> Poison.Encoder.encode({}, [])
      "[]"

      iex> Poison.Encoder.encode({1, 2, 3}, [])
      "[1, 2, 3]"

  """
  def encode(tuple, _options) do
    tuple
    |> Tuple.to_list
    |> Poison.encode!
  end
end


defimpl Poison.Encoder, for: VirtualDateField do

  @doc """
  JSON serialization behaviour for `virtualDateField`. Does not include any
  information about associations besides the stored `field_ids`.

  ## Examples

      iex> Plenario.Schemas.VirtualDateField
      iex> Poison.Encoder.encode(%VirtualDateField{}, [])
      nil

      iex> Plenario.Schemas.VirtualDateField
      iex> Poison.Encoder.encode({1, 2, 3}, [])
      nil

  """
  def encode(vdfield, _options) do
    field_atoms = [:year_field_id, :month_field_id, :day_field_id,
      :hour_field_id, :minute_field_id, :second_field_id]

    Poison.encode!(
      Map.merge(
        %{name: vdfield.name},
        Plenario.Encodings.Helpers.field_name_map(vdfield, field_atoms)
      ))
  end
end


defimpl Poison.Encoder, for: VirtualPointField do

  @doc """
  JSON serialization behaviour for `virtualPointField`. Does not include any
  information about associations besides the stored `field_ids`.

  ## Examples

      iex> Plenario.Schemas.VirtualPointField
      iex> Poison.Encoder.encode(%VirtualPointField{}, [])
      nil

      iex> Plenario.Schemas.VirtualPointField
      iex> Poison.Encoder.encode({1, 2, 3}, [])
      nil

  """
  def encode(vpfield, _options) do
    field_atoms = [:lat_field_id, :lon_field_id, :loc_field_id]

    Poison.encode!(
      Map.merge(
        %{name: vpfield.name},
        Plenario.Encodings.Helpers.field_name_map(vpfield, field_atoms)
      ))
  end
end
