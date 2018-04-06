import Plenario.Actions.DataSetFieldActions, only: [field_names: 1]
import Plenario.Encodings.Helpers
alias Plenario.Schemas.{
  UniqueConstraint,
  VirtualDateField,
  VirtualPointField
}


defimpl String.Chars, for: Map do
  def to_string(map) when is_map(map) do
    Poison.encode!(map)
  end
end


defimpl Poison.Encoder, for: Tuple do
  def encode(tuple, _options) do
    tuple
    |> Tuple.to_list
    |> Poison.encode!
  end
end


defimpl Poison.Encoder, for: UniqueConstraint do
  def encode(constraint, _options) do
    Poison.encode!(%{
      name: constraint.name,
      fields: field_names(constraint.field_ids)
    })
  end
end


defimpl Poison.Encoder, for: VirtualDateField do
  def encode(vdfield, _options) do
    field_atoms = [:year_field_id, :month_field_id, :day_field_id,
      :hour_field_id, :minute_field_id, :second_field_id]

    Poison.encode!(
      Map.merge(
        %{name: vdfield.name},
        field_name_map(vdfield, field_atoms)
      ))
  end
end


defimpl Poison.Encoder, for: VirtualPointField do
  def encode(vpfield, _options) do
    field_atoms = [:lat_field_id, :lon_field_id, :loc_field_id]

    Poison.encode!(
      Map.merge(
        %{name: vpfield.name},
        field_name_map(vpfield, field_atoms)
      ))
  end
end

