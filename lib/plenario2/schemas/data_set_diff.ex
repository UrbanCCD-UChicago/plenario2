defmodule Plenario2.Schemas.DataSetDiff do
  use Ecto.Schema

  schema "data_set_diffs" do
    field(:column, :string)
    field(:original, :string)
    field(:update, :string)
    field(:changed_on, :utc_datetime)
    field(:constraint_values, :map)

    belongs_to(:meta, Plenario2.Schemas.Meta)
    belongs_to(:data_set_constraint, Plenario2.Schemas.DataSetConstraint)
    belongs_to(:etl_job, Plenario2.Schemas.EtlJob)
  end
end
