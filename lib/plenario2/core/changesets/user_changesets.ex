defmodule Plenario2.Core.Changesets.UserChangeset do
  import Ecto.Changeset
  alias Comeonin.Bcrypt

  def create(struct, params) do
    struct
    |> cast(params, [:name, :organization, :org_role, :plaintext_password, :email_address])
    |> validate_required([:name, :email_address, :plaintext_password])
    |> unique_constraint(:email_address)
    |> validate_format(:email, ~r/.+@.+\..+/)
    |> put_change(:hashed_password, Bcrypt.hashpwsalt(params.plaintext_password))
  end
end
