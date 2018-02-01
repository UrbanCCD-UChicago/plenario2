defmodule PlenarioMailer.Schemas.AdminUserNote do
  use Ecto.Schema

  schema "admin_user_notes" do
    field(:note, :string)
    field(:should_email, :boolean, default: false)
    field(:acknowledged, :boolean, default: false)

    timestamps()

    belongs_to(:admin, PlenarioAuth.User, foreign_key: :admin_id)
    belongs_to(:user, PlenarioAuth.User, foreign_key: :user_id)
    belongs_to(:meta, Plenario.Schemas.Meta)
    belongs_to(:etl_job, Plenario.Schemas.EtlJob)
    belongs_to(:export_job, Plenario.Schemas.ExportJob)
  end
end
