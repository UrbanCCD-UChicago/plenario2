import Plenario.Actions.DataSetFieldActions, only: [field_names: 1]


defmodule Plenario.Encodings.Helpers do
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
