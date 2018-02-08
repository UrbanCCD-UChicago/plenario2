defmodule PlenarioEtl.Schemas.DataSetDiff do
  @moduledoc """
  Defines the schema for DataSetDiff.

  - `column` is the name of the column that has the updated value
  - `original` is the existing/original value of the cell
  - `update` is the new/updated value of the cell
  - `changed_on` is the timestamp of the change
  - `constraint_values` is a map of the column names and cell values where the
    unique constraint was violated
  """

  use Ecto.Schema

  schema "data_set_diffs" do
    field(:column, :string)
    field(:original, :string)
    field(:update, :string)
    field(:changed_on, :utc_datetime)
    field(:constraint_values, :map)

    timestamps(type: :utc_datetime)

    belongs_to(:meta, Plenario.Schemas.Meta)
    belongs_to(:unique_constraint, Plenario.Schemas.UniqueConstraint)
    belongs_to(:etl_job, PlenarioEtl.Schemas.EtlJob)
  end
end
