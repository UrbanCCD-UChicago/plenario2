defmodule PlenarioMailer.Schemas.AdminUserNote do
  @moduledoc """
  Defines the schema for AdminUserNote.

  - `message` is the message being sent
  - `should_email` indicates whether or not the user should be emailed
  - `acknowledged` indicated whether or not the user has read the message

  The `meta`, `etl_job` and `export_job` refs help give context to what the
  message is about -- if a job failed or if a meta was disallowed for example.
  """

  use Ecto.Schema

  schema "admin_user_notes" do
    field(:message, :string)
    field(:should_email, :boolean, default: false)
    field(:acknowledged, :boolean, default: false)

    timestamps(type: :utc_datetime)

    belongs_to(:admin, Plenario.Schemas.User, foreign_key: :admin_id)
    belongs_to(:user, Plenario.Schemas.User, foreign_key: :user_id)
    belongs_to(:meta, Plenario.Schemas.Meta)
    belongs_to(:etl_job, PlenarioEtl.Schemas.EtlJob)
    belongs_to(:export_job, PlenarioExport.Schemas.ExportJob)
  end
end