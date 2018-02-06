defmodule PlenarioWeb.Web.MeController do
  use PlenarioWeb, :web_controller

  alias Plenario.Actions.{MetaActions, UserActions}

  alias PlenarioAuth

  def index(conn, _) do
    user = Guardian.Plug.current_resource(conn)
    metas = MetaActions.list(for_user: user)
    render(conn, "index.html", user: user, metas: metas)
  end

  def edit(conn, _) do
    user = Guardian.Plug.current_resource(conn)
    changeset = UserActions.edit(user)
    action = me_path(conn, :update)
    render(conn, "edit.html", user: user, changeset: changeset, action: action)
  end

  def update(conn, %{"user" => %{"name" => name, "email" => email, "bio" => bio}}) do
    user = Guardian.Plug.current_resource(conn)
    case UserActions.update(user, name: name, email: email, bio: bio) do
      {:ok, user} ->
        conn
        |> put_flash(:success, "#{user.name} updated.")
        |> redirect(to: me_path(conn, :index))

      {:error, changeset} ->
        action = me_path(conn, :update)
        conn
        |> put_flash(:error, "Please review errors below.")
        |> put_status(:bad_request)
        |> render("edit.html", user: user, changeset: changeset, action: action)
    end
  end

  def edit_password(conn, _) do
    action = me_path(conn, :update_password)
    render(conn, "change-password.html", action: action)
  end

  def update_password(conn, %{"passwd" => %{"old" => old, "new" => new, "confirm" => confirm}}) do
    user = Guardian.Plug.current_resource(conn)
    action = me_path(conn, :update_password)
    case PlenarioAuth.authenticate(user.email, old) do
      {:ok, _} ->
        case new == confirm do
          true ->
            case UserActions.update(user, password: new) do
              {:ok, user} ->
                conn
                |> put_flash(:success, "Password updated!")
                |> redirect(to: me_path(conn, :index))

              {:error, changeset} ->
                Enum.each(changeset.errors, fn e -> put_flash(conn, :error, e.message) end)
                conn
                |> put_status(:bad_request)
                |> render("change-password.html", action: action)
            end

          false ->
            conn
            |> put_flash(:error, "Passwords did not match.")
            |> put_status(:bad_request)
            |> render("change-password.html", action: action)
        end

      {:error, _} ->
        conn
        |> put_flash(:error, "Incorrect password.")
        |> put_status(:bad_request)
        |> render("change-password.html", action: action)
    end
  end
end
