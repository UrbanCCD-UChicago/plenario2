defmodule Plenario2.Core.Schemas.DataSetDiff do
  use Ecto.Schema

  schema "data_set_diffs" do
    field(:column, :string)
    field(:original, :string)
    field(:updated, :string)
    field(:changed_on, :utc_datetime)
    field(:constraint_values, :map)

    belongs_to(:meta, Plenario2.Core.Schemas.Meta)
    belongs_to(:data_set_constraint, Plenario2.Core.Schemas.DataSetConstraint)
    belongs_to(:etl_job, Plenario2.Core.Schemas.EtlJob)
  end
end
