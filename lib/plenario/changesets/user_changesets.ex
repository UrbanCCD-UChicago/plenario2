defmodule Plenario.Changesets.UserChangesets do
  @moduledoc """
  This module defines functions used to create and update changesets for
  the User schema.
  """

  import Ecto.Changeset

  alias Plenario.Schemas.User

  @type create_params :: %{
    name: String.t(),
    email: String.t(),
    password: String.t()
  }

  @type update_params :: %{
    name: String.t(),
    email: String.t(),
    password: String.t(),
    bio: String.t(),
    is_active: boolean,
    is_admin: boolean
  }

  @required_keys [:name, :email]

  @create_keys [:name, :email, :password]

  @update_keys [:name, :email, :password, :bio, :is_active, :is_admin]

  @email_regex ~r/.+@.+\..+/

  @spec new() :: Ecto.Changeset.t()
  def new(), do: %User{} |> cast(%{}, @create_keys)

  @spec create(params :: create_params) :: Ecto.Changeset
  def create(params) do
    %User{}
    |> cast(params, @create_keys)
    |> validate_required(@create_keys)
    |> unique_constraint(:email)
    |> validate_format(:email, @email_regex)
    |> hash_password()
    |> put_change(:is_active, true)
  end

  @spec update(instance :: User, params :: update_params) :: Ecto.Changeset
  def update(instance, params) do
    instance
    |> cast(params, @update_keys)
    |> validate_required(@required_keys)
    |> unique_constraint(:email)
    |> validate_format(:email, @email_regex)
    |> hash_password()
  end

  defp hash_password(%Ecto.Changeset{valid?: true, changes: %{password: plaintext}} = changeset) do
    hashed = Comeonin.Bcrypt.hashpwsalt(plaintext)
    put_change(changeset, :password_hash, hashed)
  end

  defp hash_password(changeset), do: changeset
end
