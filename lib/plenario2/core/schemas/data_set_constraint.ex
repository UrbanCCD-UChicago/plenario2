defmodule Plenario2.Core.Schemas.DataSetConstraint do
  use Ecto.Schema

  schema "data_set_constraints" do
    field :field_names,     {:array, :string}
    field :constraint_name, :string

    belongs_to  :meta,            Plenario2.Core.Schemas.Meta
    has_many    :data_set_diffs,  Plenario2.Core.Schemas.DataSetDiff
  end
end
