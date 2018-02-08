defmodule Plenario.Actions.UserActions do
  @moduledoc """
  This module provides a high level API for interacting with the
  User schema -- creating, updating, getting, ...
  """

  alias Plenario.Repo

  alias Plenario.Schemas.User

  alias Plenario.Changesets.UserChangesets

  alias Plenario.Queries.UserQueries

  @type ok_instance :: {:ok, User} | {:error, Ecto.Changeset.t()}

  @doc """
  This is a convenience function for generating empty changesets to more
  easily construct forms in Phoenix templates.
  """
  @spec new() :: Ecto.Changeset.t()
  def new(), do: UserChangesets.new()

  @doc """
  Create a new instance of User in the database.

  If the related Meta instance's state field is not "new" though, this
  will error out -- you cannot add a new User to and active Meta.
  """
  @spec create(name :: String.t(), email :: String.t(), password :: String.t()) :: ok_instance
  def create(name, email, password) do
    params = %{
      name: name,
      email: email,
      password: password
    }
    UserChangesets.create(params)
    |> Repo.insert()
  end

  @doc """
  This is a convenience function for generating prepopulated changesets
  to more easily construct change forms in Phoenix templates.
  """
  @spec edit(instance :: User) :: Ecto.Changeset.t()
  def edit(instance), do: UserChangesets.update(instance, %{})

  @doc """
  Updates a given User's attributes.

  If the related Meta instance's state field is not "new" though, this
  will error out -- you cannot add a new User to and active Meta.
  """
  @spec update(instance :: User, opts :: Keyword.t()) :: ok_instance
  def update(instance, opts \\ []) do
    params = Enum.into(opts, %{})
    UserChangesets.update(instance, params)
    |> Repo.update()
  end

  @doc """
  Convenience function to set a User's is_active attribute to true.
  """
  @spec activate(user :: User) :: ok_instance
  def activate(user), do: update(user, is_active: true)

  @doc """
  Convenience function to set a User's is_active attribute to false.
  """
  @spec archive(user :: User) :: ok_instance
  def archive(user), do: update(user, is_active: false)

  @doc """
  Convenience function to set a User's is_admin attribute to true.
  """
  @spec promote_to_admin(user :: User) :: ok_instance
  def promote_to_admin(user), do: update(user, is_admin: true)

  @doc """
  Convenience function to set a User's is_admin attribute to false.
  """
  @spec strip_admin_privs(user :: User) :: ok_instance
  def strip_admin_privs(user), do: update(user, is_admin: false)

  @doc """
  Convenience function to change a User's password.
  """
  @spec change_password(user :: User, new_password :: String.t()) :: ok_instance
  def change_password(user, new_password), do: update(user, password: new_password)

  @doc """
  Gets a list of User from the database.

  This can be optionally filtered using the opts. See
  UserQueries.handle_opts for more details.
  """
  @spec list(opts :: Keyword.t() | nil) :: list(User)
  def list(opts \\ []) do
    UserQueries.list()
    |> UserQueries.handle_opts(opts)
    |> Repo.all()
  end

  @doc """
  Gets a single User from the database.
  """
  @spec get(identifier :: integer | String.t()) :: User | nil
  def get(identifier), do: UserQueries.get(identifier) |> Repo.one()
end
