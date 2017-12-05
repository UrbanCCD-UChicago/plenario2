defmodule Plenario2Auth.UserActions do
  import Ecto.Query
  alias Comeonin.Bcrypt
  alias Plenario2.Repo
  alias Plenario2Auth.User
  alias Plenario2Auth.UserChangesets
  alias Plenario2Auth.UserQueries, as: Q

  ##
  # get one

  def get_from_id(id), do: Q.get_by_id(id) |> Repo.one()

  def get_from_email(email), do: Q.get_by_email(email) |> Repo.one()

  ##
  # create

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

  ##
  # edit

  def promote_to_admin(user) do
    UserChangesets.update_admin(user, %{is_admin: true, is_trusted: true})
    |> Repo.update()
  end

  def strip_admin(user) do
    UserChangesets.update_admin(user, %{is_admin: false})
    |> Repo.update()
  end

  def trust(user) do
    UserChangesets.update_trusted(user, %{is_trusted: true})
    |> Repo.update()
  end

  def untrust(user) do
    UserChangesets.update_trusted(user, %{is_trusted: false})
    |> Repo.update()
  end

  def activate(user) do
    UserChangesets.update_active(user, %{is_active: true})
    |> Repo.update()
  end

  def archive(user) do
    UserChangesets.update_active(user, %{is_active: false})
    |> Repo.update()
  end

  ##
  # auth

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
