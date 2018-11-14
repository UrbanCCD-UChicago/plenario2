defmodule Plenario.UserActions do
  import Plenario.ActionUtils

  alias Plenario.{
    Repo,
    User,
    UserQueries
  }

  # CRUD

  def list(opts \\ []) do
    UserQueries.list()
    |> UserQueries.handle_opts(opts)
    |> Repo.all()
  end

  def get(id, opts \\ []) do
    user =
      UserQueries.get(id)
      |> UserQueries.handle_opts(opts)
      |> Repo.one()

    case user do
      nil -> {:error, nil}
      _ -> {:ok, user}
    end
  end

  def get!(id, opts \\ []) do
    UserQueries.get(id)
    |> UserQueries.handle_opts(opts)
    |> Repo.one!()
  end

  def create(params) do
    params = params_to_map(params)

    User.changeset(%User{}, params)
    |> Repo.insert()
  end

  def update(user, params) do
    params = params_to_map(params)

    User.changeset(user, params)
    |> Repo.update()
  end

  def delete(user) do
    user
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.no_assoc_constraint(:data_sets)
    |> Repo.delete()
  end

  # Other Actions

  def authenticate(email, plaintext) do
    error = "Incorrect email or password"

    case get(email) do
      {:ok, user} ->
        case Comeonin.Bcrypt.checkpw(plaintext, user.password_hash) do
          true -> {:ok, user}
          false -> {:error, error}
        end

      _ ->
        {:error, error}
    end
  end
end
