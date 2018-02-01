defmodule PlenarioAuth.User do
  use Ecto.Schema

  schema "users" do
    field(:name, :string)
    field(:email_address, :string)
    field(:hashed_password, :string)
    field(:organization, :string)
    field(:org_role, :string)
    field(:is_active, :boolean)
    field(:is_trusted, :boolean)
    field(:is_admin, :boolean)

    field(:plaintext_password, :string, virtual: true)

    timestamps()

    has_many(:metas, Plenario.Schemas.Meta)
    has_many(:export_jobs, Plenario.Schemas.ExportJob)
  end

  def get_status_name(user) do
    if user.is_admin do
      "Admin"
    else
      if user.is_trusted do
        "Trusted"
      else
        if user.is_active do
          "Active"
        else
          "Archived"
        end
      end
    end
  end
end
