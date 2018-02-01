defmodule Plenario.Schemas.DataSetConstraint do
  use Ecto.Schema

  schema "data_set_constraints" do
    field(:field_names, {:array, :string})
    field(:constraint_name, :string)

    belongs_to(:meta, Plenario.Schemas.Meta)
    has_many(:data_set_diffs, Plenario.Schemas.DataSetDiff)
  end
end
