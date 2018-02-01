defmodule Plenario.Changesets.UserChangesets do
  @moduledoc """
  This module defines functions used to create Ecto Changesets for various
  states of the User schema.
  """

  import Ecto.Changeset

  alias Plenario.Schemas.User

  @typedoc """
  A verbose map of parameter types for :create/1
  """
  @type create_params :: %{
    name: String.t(),
    email: String.t(),
    password: String.t(),
    bio: String.t() | nil
  }

  @typedoc """
  A verbose map of parameter types for :update/2
  """
  @type update_params :: %{
    name: String.t(),
    email: String.t(),
    bio: String.t() | nil
  }

  @email_regex ~r/^.+@.+\..+$/

  @create_param_keys [:name, :email, :password, :bio]

  @doc """
  Generates a changeset for creating a new User

  ## Examples

    empty_changeset_for_form =
      UserChangesets.create(%{})

    result =
      UserChangeset.create(%{what: "ever"})
      |> Repo.insert()
    case result do
      {:ok, user} -> do_something(with: user)
      {:error, changeset} -> do_something_else(with: changeset)
    end
  """
  @spec create(params :: create_params) :: Ecto.Changeset.t()
  def create(params) do
    %User{}
    |> cast(params, @create_param_keys)
    |> validate_required([:name, :email, :password])
    |> unique_constraint(:email)
    |> validate_format(:email, @email_regex)
    |> hash_password()
  end

  @doc """
  Generates a changeset for updating a User's name, email or bio. If you need
  to update other values of the user, there are specialty changeset functions
  to handle those cases.

  ## Example

    result =
      UserChangeset.update(user, %{name: "Bob", email: "bob@example.com"})
      |> Repo.update()
    case result do
      {:ok, bob} -> say_hi(to: bob)
      {:error, changeset} -> prompt_for_fixes(for: changeset)
    end
  """
  @spec update(user :: User, params :: update_params) :: Ecto.Changeset.t()
  def update(user, params) do
    user
    |> cast(params, [:name, :email, :bio])
    |> validate_required([:name, :email])
    |> unique_constraint(:email)
    |> validate_format(:email, @email_regex)
  end

  @doc """
  Generates a changeset for updating a User's password. If you need
  to update other values of the user, there are specialty changeset functions
  to handle those cases.

  ## Example

    {:ok, user} =
      UserChangesets.create(%{name: "Test", email: "test@example.com", password: "password1"})
      |> Repo.insert()

    {:ok, user} =
      UserChangesets.update_password(user, %{password: "Th1s is a stronger password!"})
      |> Repo.update()
  """
  @spec update_password(user :: User, params :: %{password: String.t()}) :: Ecto.Changeset.t()
  def update_password(user, params) do
    user
    |> cast(params, [:password])
    |> validate_required([:password])
    |> hash_password()
  end

  @doc """
  Generates a changeset for updating a User's is_active flag. If you need
  to update other values of the user, there are specialty changeset functions
  to handle those cases.

  ## Example

    {:ok, user} =
      UserChangesets.create(%{name: "Test", email: "test@example.com", password: "password1"})
      |> Repo.insert()

    # archive this user
    {:ok, user} =
      UserChangesets.update_active(user, %{is_active: false})
      |> Repo.update()
  """
  @spec update_active(user :: User, params :: %{is_active: boolean}) :: Ecto.Changeset.t()
  def update_active(user, params) do
    user
    |> cast(params, [:is_active])
  end

  @doc """
  Generates a changeset for updating a User's is_admin flag. If you need
  to update other values of the user, there are specialty changeset functions
  to handle those cases.

  ## Example

    {:ok, user} =
      UserChangesets.create(%{name: "Test", email: "test@example.com", password: "password1"})
      |> Repo.insert()

    # promote to admin
    {:ok, user} =
      UserChangesets.update_admin(user, %{is_admin: true})
      |> Repo.update()
  """
  @spec update_admin(user :: User, params :: %{is_admin: boolean}) :: Ecto.Changeset.t()
  def update_admin(user, params) do
    user
    |> cast(params, [:is_admin])
  end

  defp hash_password(%Ecto.Changeset{valid?: true, changes: %{password: plaintext}} = changeset) do
    hashed = Comeonin.Bcrypt.hashpwsalt(plaintext)
    put_change(changeset, :password_hash, hashed)
  end

  defp hash_password(changeset), do: changeset
end
