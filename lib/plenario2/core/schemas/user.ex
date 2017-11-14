defmodule Plenario2.Core.Schemas.User do
  use Ecto.Schema

  schema "users" do
    field(:name, :string)
    field(:organization, :string)
    field(:org_role, :string)
    field(:hashed_password, :string)
    field(:email_address, :string)
    field(:is_active, :boolean)
    field(:is_trusted, :boolean)
    field(:is_admin, :boolean)

    field(:plaintext_password, :string, virtual: true)

    timestamps()

    has_many(:metas, Plenario2.Core.Schemas.Meta)
    has_many(:export_jobs, Plenario2.Core.Schemas.ExportJob)
  end
end
