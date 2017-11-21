defmodule Plenario2.Schemas.DataSetConstraint do
  use Ecto.Schema

  schema "data_set_constraints" do
    field(:field_names, {:array, :string})
    field(:constraint_name, :string)

    belongs_to(:meta, Plenario2.Schemas.Meta)
    has_many(:data_set_diffs, Plenario2.Schemas.DataSetDiff)
  end
end
