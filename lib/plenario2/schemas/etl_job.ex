defmodule Plenario2.Schemas.EtlJob do
  use Ecto.Schema

  schema "etl_jobs" do
    field(:state, :string)
    field(:started_on, :utc_datetime)
    field(:completed_on, :utc_datetime)
    field(:error_message, :string)

    belongs_to(:meta, Plenario2.Schemas.Meta)
    has_many(:data_set_diffs, Plenario2.Schemas.DataSetDiff)
  end
end
