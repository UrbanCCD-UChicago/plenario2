defmodule Plenario2Auth.UserActions do
  @moduledoc """
  This module provides the Common API for working with User
  entities. This is the main business logic for
  application <-> database activities. All controllers and
  other applications should use these functions.
  """

  alias Comeonin.Bcrypt

  alias Plenario2.Repo
  alias Plenario2Auth.User
  alias Plenario2Auth.UserChangesets
  alias Plenario2Auth.UserQueries, as: Q

  @doc """
  For a given ID, get a user from the database.
  """
  @spec get_from_id(id :: integer) :: %User{} | nil
  def get_from_id(id), do: Q.get_by_id(id) |> Repo.one()

  @doc """
  for a given email address, get a user from the database.
  """
  @spec get_from_email(email :: String.t()) :: %User{} | nil
  def get_from_email(email), do: Q.get_by_email(email) |> Repo.one()

  @doc """
  Creates a new user entry in the database from the given set of parameters.
  """
  @spec create(
          name :: String.t(),
          password :: String.t(),
          email :: String.t(),
          organization :: String.t(),
          role :: String.t()
        ) :: {:ok, %User{} | :error, Ecto.Changeset.t()}
  def create(name, password, email, organization \\ nil, role \\ nil) do
    params = %{
      name: name,
      email_address: email,
      plaintext_password: password,
      organization: organization,
      org_role: role,
      is_active: true,
      is_trusted: false,
      is_admin: false
    }

    UserChangesets.create(%User{}, params)
    |> Repo.insert()
  end

  @doc """
  Given a user, this updates their name.
  """
  @spec update_name(user :: %User{}, new_name :: String.t()) ::
          {:ok, %User{} | :error, Ecto.Changeset.t()}
  def update_name(user, new_name) do
    UserChangesets.update_name(user, %{name: new_name})
    |> Repo.update()
  end

  @doc """
  Given a user, this updates their email address.
  """
  @spec update_email_address(user :: %User{}, new_email :: String.t()) ::
          {:ok, %User{} | :error, Ecto.Changeset.t()}
  def update_email_address(user, new_email) do
    UserChangesets.update_email_address(user, %{email_address: new_email})
    |> Repo.update()
  end

  @doc """
  Given a user, this updates their organization information.

  Options for `opts` param:
    - organization
    - org_role
  """
  @spec update_org_info(user :: %User{}, opts :: [{atom, String.t()}]) ::
          {:ok, %User{} | :error, Ecto.Changeset.t()}
  def update_org_info(user, opts \\ []) do
    defaults = [
      organization: :unchanged,
      org_role: :unchanged
    ]

    options = Keyword.merge(defaults, opts) |> Enum.into(%{})

    params =
      Enum.filter(options, fn {_, value} -> value != :unchanged end)
      |> Enum.into(%{})

    UserChangesets.update_org_info(user, params)
    |> Repo.update()
  end

  @doc """
  Given a user, this updates their password.
  """
  @spec update_password(user :: %User{}, new_password :: String.t()) ::
          {:ok, %User{} | :error, Ecto.Changeset.t()}
  def update_password(user, new_password) do
    UserChangesets.update_password(user, %{plaintext_password: new_password})
    |> Repo.update()
  end

  @doc """
  Given a user, this updates their `is_admin` and `is_trusted` fields to true.
  """
  @spec promote_to_admin(user :: %User{}) :: {:ok, %User{} | :error, Ecto.Changeset.t()}
  def promote_to_admin(user) do
    UserChangesets.update_admin(user, %{is_admin: true, is_trusted: true})
    |> Repo.update()
  end

  @doc """
  Given a user, this updates their `is_admin` bit to false, but leaves them intact as a trusted user.
  """
  @spec strip_admin(user :: %User{}) :: {:ok, %User{} | :error, Ecto.Changeset.t()}
  def strip_admin(user) do
    UserChangesets.update_admin(user, %{is_admin: false})
    |> Repo.update()
  end

  @doc """
  Given a user, this sets their `is_trusted` bit to true.
  """
  @spec trust(user :: %User{}) :: {:ok, %User{} | :error, Ecto.Changeset.t()}
  def trust(user) do
    UserChangesets.update_trusted(user, %{is_trusted: true})
    |> Repo.update()
  end

  @doc """
  Given a user, this sets their `is_trusted` bit to false.
  """
  @spec untrust(user :: %User{}) :: {:ok, %User{} | :error, Ecto.Changeset.t()}
  def untrust(user) do
    UserChangesets.update_trusted(user, %{is_trusted: false})
    |> Repo.update()
  end

  @doc """
  Given a user, this sets their `is_active` bit to true.
  """
  @spec activate(user :: %User{}) :: {:ok, %User{} | :error, Ecto.Changeset.t()}
  def activate(user) do
    UserChangesets.update_active(user, %{is_active: true})
    |> Repo.update()
  end

  @doc """
  Given a user, this sets their `is_active` bit to false. Since we don't ever want
  to delete users, we set them as inactive or archived so that they are unable
  to authenticate to the system.
  """
  @spec archive(user :: %User{}) :: {:ok, %User{} | :error, Ecto.Changeset.t()}
  def archive(user) do
    UserChangesets.update_active(user, %{is_active: false})
    |> Repo.update()
  end

  @doc """
  From a given email and password pair, can a user be found in
  the database and do the password hashes match?
  """
  @spec authenticate(email :: String.t(), password :: String.t()) :: boolean
  def authenticate(email, password) do
    get_from_email(email)
    |> check_password(password)
  end

  defp check_password(nil, _), do: {:error, "Incorrect email or password"}

  defp check_password(user, password) do
    case Bcrypt.checkpw(password, user.hashed_password) do
      true -> {:ok, user}
      false -> {:error, "Incorrect email or password"}
    end
  end
end
