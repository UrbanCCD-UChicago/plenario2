defmodule Plenario2.Actions.UserActions do
  import Ecto.Query
  alias Comeonin.Bcrypt
  alias Plenario2.Changesets.UserChangesets
  alias Plenario2.Schemas.User
  alias Plenario2.Repo

  def create(name, password, email, organization \\ nil, role \\ nil) do
    params = %{
      name: name,
      organization: organization,
      org_role: role,
      plaintext_password: password,
      email_address: email,
      is_active: true,
      is_trusted: false,
      is_admin: false
    }

    UserChangesets.create(%User{}, params)
    |> Repo.insert()
  end

  def list(), do: Repo.all(User)

  def get_from_pk(pk), do: Repo.one(from(u in User, where: u.id == ^pk))

  def archive(user) do
    UserChangesets.set_active_flag(user, %{is_active: false})
    |> Repo.update()
  end

  def activate_archived(user) do
    UserChangesets.set_active_flag(user, %{is_active: true})
    |> Repo.update()
  end

  def trust(user) do
    UserChangesets.set_trusted_flag(user, %{is_trusted: true})
    |> Repo.update()
  end

  def untrust(user) do
    UserChangesets.set_trusted_flag(user, %{is_trusted: false})
    |> Repo.update()
  end

  def promote_to_admin(user) do
    UserChangesets.set_admin_flag(user, %{is_admin: true})
    |> Repo.update()
  end

  def revoke_admin(user) do
    UserChangesets.set_admin_flag(user, %{is_admin: false})
    |> Repo.update()
  end

  def update_name(user, new_name) do
    UserChangesets.update_name(user, %{name: new_name})
    |> Repo.update()
  end

  def update_password(user, new_plaintext) do
    UserChangesets.update_password(user, %{plaintext_password: new_plaintext})
    |> Repo.update()
  end

  def update_email_address(user, new_email) do
    UserChangesets.update_email_address(user, %{email_address: new_email})
    |> Repo.update()
  end

  def update_org_info(user, options \\ []) do
    defaults = [org: :unchanged, role: :unchanged]
    options = Keyword.merge(defaults, options) |> Enum.into(%{})
    %{org: org, role: role} = options

    params =
      cond do
        org != :unchanged and role != :unchanged -> %{organization: org, org_role: role}
        org != :unchanged -> %{organization: org}
        role != :unchanged -> %{org_role: role}
      end

    UserChangesets.update_org_info(user, params)
    |> Repo.update()
  end

  def authenticate(email_address, plaintext_password) do
    error = {:error, "Email address or password is incorrect"}
    user = Repo.one(from(u in User, where: u.email_address == ^email_address))

    if user == nil do
      error
    else
      if Bcrypt.checkpw(plaintext_password, user.hashed_password) do
        {:ok, user}
      else
        error
      end
    end
  end
end
