defmodule Plenario2.Schemas.AdminUserNote do
  use Ecto.Schema

  schema "admin_user_notes" do
    field(:note, :string)
    field(:should_email, :boolean, default: false)
    field(:acknowledged, :boolean, default: false)

    timestamps()

    belongs_to(:admin, Plenario2Auth.User, foreign_key: :admin_id)
    belongs_to(:user, Plenario2Auth.User, foreign_key: :user_id)
    belongs_to(:meta, Plenario2.Schemas.Meta)
    belongs_to(:etl_job, Plenario2.Schemas.EtlJob)
    belongs_to(:export_job, Plenario2.Schemas.ExportJob)
  end
end
