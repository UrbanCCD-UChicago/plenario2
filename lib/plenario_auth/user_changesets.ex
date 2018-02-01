defmodule PlenarioAuth.UserChangesets do
  @moduledoc """
  This module defines the functions that handle creating
  Ecto changesets for the User schema.

  Rather than having a monolithin `update` function, we've decided
  to encapsulate important functional actions to themselves, such
  as updating email addresses or setting authorization flags.
  """

  import Ecto.Changeset

  alias Comeonin.Bcrypt

  alias PlenarioAuth.User

  @email_regex ~r/.+@.+\..+/

  @doc """
  Performs the casting and validation needed to create a new
  user entry in the database.

  Keys in the `params` can be:
    - name
    - email_address
    - plaintext_password
    - organization
    - org_role
    - is_active
    - is_trusted
    - is_admin

  Special feature of this changeset is it hashes the given
  plaintext password and stores the hash in the database, discarding
  the plaintext version.
  """
  @spec create(user :: %User{}, params :: %{}) :: Ecto.Changeset.t()
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
    |> hash_password()
  end

  @doc """
  Performs the casting and validation needed to update a user's
  name in the database.
  """
  @spec update_name(user :: %User{}, params :: %{name: String.t()}) :: Ecto.Changeset.t()
  def update_name(user, params) do
    user
    |> cast(params, [:name])
  end

  @doc """
  Performs the casting and validation need to update a user's
  email address in the database.
  """
  @spec update_email_address(user :: %User{}, params :: %{email_address: String.t()}) ::
          Ecto.Changeset.t()
  def update_email_address(user, params) do
    user
    |> cast(params, [:email_address])
    |> validate_required([:email_address])
    |> unique_constraint(:email_address)
    |> validate_format(:email_address, @email_regex)
  end

  @doc """
  Performs the casting and validation need to update a user's
  password hash in the database.

  Special feature of this changeset is it hashes the given
  plaintext password and stores the hash in the database, discarding
  the plaintext version.
  """
  @spec update_password(user :: %User{}, params :: %{plaintext_password: String.t()}) ::
          Ecto.Changeset.t()
  def update_password(user, params) do
    user
    |> cast(params, [:plaintext_password])
    |> validate_required([:plaintext_password])
    |> hash_password()
  end

  @doc """
  Performs the casting and validation need to update a user's
  organization information in the database.
  """
  @spec update_org_info(
          user :: %User{},
          params :: %{organization: String.t(), org_role: String.t()}
        ) :: Ecto.Changeset.t()
  def update_org_info(user, params) do
    user
    |> cast(params, [:organization, :org_role])
  end

  @doc """
  Performs the casting and validation need to update a user's
  `is_active` flag in the database.
  """
  @spec update_active(user :: %User{}, params :: %{is_active: boolean}) :: Ecto.Changeset.t()
  def update_active(user, params) do
    user
    |> cast(params, [:is_active])
  end

  @doc """
  Performs the casting and validation need to update a user's
  `is_trusted` flag in the database.
  """
  @spec update_trusted(user :: %User{}, params :: %{is_active: boolean}) :: Ecto.Changeset.t()
  def update_trusted(user, params) do
    user
    |> cast(params, [:is_trusted])
  end

  @doc """
  Performs the casting and validation need to update a user's
  `is_admin` flag in the database.
  """
  @spec update_admin(user :: %User{}, params :: %{is_admin: boolean}) :: Ecto.Changeset.t()
  def update_admin(user, params) do
    user
    |> cast(params, [:is_admin, :is_trusted])
  end

  ##
  # operations

  defp hash_password(
         %Ecto.Changeset{valid?: true, changes: %{plaintext_password: plaintext}} = changeset
       ) do
    changeset
    |> put_change(:hashed_password, Bcrypt.hashpwsalt(plaintext))
  end

  defp hash_password(changeset), do: changeset
end
