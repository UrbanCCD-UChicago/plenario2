defmodule Plenario2.Core.Schemas.EtlJob do
  use Ecto.Schema

  schema "etl_jobs" do
    field :state,       :string
    field :started_on,  :string
    field :ended_on,    :string

    belongs_to  :meta,            Core.Schemas.Meta
    has_many    :data_set_diffs,  Core.Schemas.DataSetDiff
  end
end
