defmodule Plenario2Auth.UserChangesets do
  import Ecto.Changeset
  alias Comeonin.Bcrypt

  @email_regex ~r/.+@.+\..+/

  def create(user, params) do
    user
    |> cast(params, [
      :name,
      :email_address,
      :plaintext_password,
      :organization,
      :org_role,
      :is_active,
      :is_trusted,
      :is_admin
    ])
    |> validate_required([:name, :email_address, :plaintext_password])
    |> unique_constraint(:email_address)
    |> validate_format(:email_address, @email_regex)
    |> hash_password(params.plaintext_password)
  end

  # def update_name(user, params) do
  #   user
  #   |> cast(params, [:name])
  # end
  #
  # def update_email_address(user, params) do
  #   user
  #   |> cast(params, [:email_address])
  #   |> validate_required([:email_address])
  #   |> unique_constraint(:email_address)
  #   |> validate_format(:email_address, @email_regex)
  # end
  #
  # def update_password(user, params) do
  #   user
  #   |> cast(params, [:plaintext_password])
  #   |> validate_required([:plaintext_password])
  #   |> hash_password(params.plaintext_password)
  # end
  #
  # def update_org_info(user, params) do
  #   user
  #   |> cast(params, [:organization, :org_role])
  # end
  #
  # def update_active(user, params) do
  #   user
  #   |> cast(params, [:is_active])
  # end
  #
  # def update_trusted(user, params) do
  #   user
  #   |> cast(params, [:is_trusted])
  # end
  #
  # def update_admin(user, params) do
  #   user
  #   |> cast(params, [:is_admin])
  # end

  ##
  # operations

  defp hash_password(changeset, plaintext) do
    changeset
    |> put_change(:hashed_password, Bcrypt.hashpwsalt(plaintext))
  end
end
