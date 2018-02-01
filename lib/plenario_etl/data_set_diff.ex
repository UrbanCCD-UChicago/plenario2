defmodule PlenarioEtl.Schemas.DataSetDiff do
  use Ecto.Schema

  schema "data_set_diffs" do
    field(:column, :string)
    field(:original, :string)
    field(:update, :string)
    field(:changed_on, :utc_datetime)
    field(:constraint_values, :map)

    belongs_to(:meta, Plenario.Schemas.Meta)
    belongs_to(:data_set_constraint, Plenario.Schemas.DataSetConstraint)
    belongs_to(:etl_job, PlenarioEtl.Schemas.EtlJob)
  end
end
