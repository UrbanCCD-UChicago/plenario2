defmodule Plenario.Actions.UserActions do
  @moduledoc """
  This module provides a high level API for interacting with User structs --
  creation, updating, archiving, admin status, listing...
  """

  alias Plenario.Repo

  alias Plenario.Changesets.UserChangesets

  alias Plenario.Queries.UserQueries

  alias Plenario.Schemas.User

  @typedoc """
  Either a tuple of {:ok, user} or {:error, changeset}
  """
  @type ok_user :: {:ok, User} | {:error, Ecto.Changeset.t()}

  @doc """
  This is a convenience function for generating changesets to more easily create
  webforms in Phoenix templates.

  ## Example

    changeset = UserActions.new()
    render(conn, "create.html", changeset: changeset)
    # And then in your template: <%= form_for @changeset, ... %>
  """
  @spec new() :: Ecto.Changeset.t()
  def new(), do: UserChangesets.create(%{})

  @doc """
  Create a new User entry in the database.

  ## Example

    {:ok, user} = UserActions.create("test", "test@example.com", "password1")
  """
  @spec create(name :: String.t(), email :: String.t(), password :: String.t(), bio :: String.t() | nil) :: ok_user
  def create(name, email, password, bio \\ nil) do
    params = %{
      name: name,
      email: email,
      password: password,
      bio: bio
    }
    UserChangesets.create(params)
    |> Repo.insert()
  end

  @doc """
  Updates a given User's name, email and/or bio.

  ## Example

    {:ok, user} = UserActions.create("test", "test@example.com", "password1")
    {:ok, _} = UserActions.update(user, bio: "just some person")
  """
  @spec update(user :: User, opts :: Keyword.t()) :: ok_user
  def update(user, opts \\ []) do
    params = Enum.into(opts, %{})
    UserChangesets.update(user, params)
    |> Repo.update()
  end

  @doc """
  Updates a given User's password.

  ## Example

    {:ok, user} = UserActions.create("test", "test@example.com", "password1")
    UserActions.change_password(user, "My @wesome new passw0rd!")
  """
  @spec change_password(user :: User, new_password :: String.t()) :: ok_user
  def change_password(user, new_password) do
    UserChangesets.update_password(user, %{password: new_password})
    |> Repo.update()
  end

  @doc """
  Sets a given User's :is_active attribute to false.

  ## Example

    {:ok, user} = UserActions.create("test", "test@example.com", "password1")
    UserActions.archive(user)
  """
  @spec archive(user :: User) :: ok_user
  def archive(user) do
    UserChangesets.update_active(user, %{is_active: false})
    |> Repo.update()
  end

  @doc """
  Sets a given User's :is_active attribute to true.

  ## Example

    {:ok, user} = UserActions.create("test", "test@example.com", "password1")
    {:ok, user} = UserActions.archive(user)
    UserActions.activate(user)
  """
  @spec activate(user :: User) :: ok_user
  def activate(user) do
    UserChangesets.update_active(user, %{is_active: true})
    |> Repo.update()
  end

  @doc """
  Sets a given User's :is_admin attribute to true.

  ## Example

    {:ok, user} = UserActions.create("test", "test@example.com", "password1")
    UserActions.promote_to_admin(user)
  """
  @spec promote_to_admin(user :: User) :: ok_user
  def promote_to_admin(user) do
    UserChangesets.update_admin(user, %{is_admin: true})
    |> Repo.update()
  end

  @doc """
  Sets a given User's :is_admin attribute to false.

  ## Example

    {:ok, user} = UserActions.create("test", "test@example.com", "password1")
    {:ok, user} = UserActions.promote_to_admin(user)
    UserActions.strip_admin_privs(user)
  """
  @spec strip_admin_privs(user :: User) :: ok_user
  def strip_admin_privs(user) do
    UserChangesets.update_admin(user, %{is_admin: false})
    |> Repo.update()
  end

  @doc """
  Gets a list of Users from the database. This can be optionally filtered using
  the opts. See UserQueries.handle_opts for more details.

  ## Examples

    all_users = UserActions.list()
    active_users = UserActions.list(active_only: true)
    admin_users = UserActions.list(admins_only: true)
  """
  @spec list(opts :: Keyword.t() | nil) :: list(User)
  def list(opts \\ []) do
    UserQueries.list()
    |> UserQueries.handle_opts(opts)
    |> Repo.all()
  end

  @doc """
  Gets a single User by either their id or email address.

  ## Examples

    user = UserActions.get(123)
    user = UserActions.get("test@example.com")
  """
  @spec get(identifier :: integer | String.t()) :: User | nil
  def get(identifier), do: UserQueries.get(identifier) |> Repo.one()
end
