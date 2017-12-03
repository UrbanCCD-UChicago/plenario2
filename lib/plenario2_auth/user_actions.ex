defmodule Plenario2Auth.UserActions do
  import Ecto.Query
  alias Comeonin.Bcrypt
  alias Plenario2.Repo
  alias Plenario2Auth.User
  alias Plenario2Auth.UserChangesets

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

  def get_from_pk(pk), do: Repo.one(from u in User, where: u.id == ^pk)

  def get_from_email(email), do: Repo.one(from u in User, where: u.email_address == ^email)

  def promote_to_admin(user) do
    UserChangesets.update_admin(user, %{is_admin: true})
    |> Repo.update()
  end

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
