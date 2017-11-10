defmodule Plenario2.Core.Schemas.ExportJob do
  use Ecto.Schema

  schema "export_jobs" do
    field :query,         :string
    field :include_diffs, :boolean
    field :export_path,   :string
    field :export_ttl,    :utc_datetime
    field :diffs_path,    :string

    timestamps()

    belongs_to :user, Plenario2.Core.Schemas.User
    belongs_to :meta, Plenario2.Core.Schemas.Meta
  end
end
