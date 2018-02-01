defmodule Plenario.Schemas.ExportJob do
  use Ecto.Schema

  schema "export_jobs" do
    field(:query, :string)
    field(:include_diffs, :boolean)
    field(:export_path, :string)
    field(:export_ttl, :utc_datetime)
    field(:diffs_path, :string)

    timestamps()

    belongs_to(:user, PlenarioAuth.User)
    belongs_to(:meta, Plenario.Schemas.Meta)
  end
end
