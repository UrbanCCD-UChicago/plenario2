defmodule Plenario2.Changesets.UserChangesets do
  import Ecto.Changeset
  alias Comeonin.Bcrypt

  def create(struct, params) do
    struct
    |> cast(params, [
         :name,
         :organization,
         :org_role,
         :plaintext_password,
         :email_address,
         :is_active,
         :is_trusted,
         :is_admin
       ])
    |> validate_required([:name, :email_address, :plaintext_password])
    |> unique_constraint(:email_address)
    |> validate_format(:email_address, ~r/.+@.+\..+/)
    |> put_change(:hashed_password, Bcrypt.hashpwsalt(params.plaintext_password))
  end

  def set_active_flag(user, params), do: user |> cast(params, [:is_active])

  def set_trusted_flag(user, params), do: user |> cast(params, [:is_trusted])

  def set_admin_flag(user, params), do: user |> cast(params, [:is_admin])

  def update_name(user, params) do
    user
    |> cast(params, [:name])
    |> validate_required([:name])
  end

  def update_email_address(user, params) do
    user
    |> cast(params, [:email_address])
    |> validate_required([:email_address])
    |> unique_constraint(:email_address)
    |> validate_format(:email_address, ~r/.+@.+\..+/)
  end

  def update_password(user, params) do
    user
    |> cast(params, [:plaintext_password])
    |> validate_required([:plaintext_password])
    |> put_change(:hashed_password, Bcrypt.hashpwsalt(params.plaintext_password))
  end

  def update_org_info(user, params) do
    user
    |> cast(params, [:organization, :org_role])
  end
end
