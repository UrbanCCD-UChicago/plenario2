defmodule PlenarioWeb.Admin.UserController do
  use PlenarioWeb, :admin_controller

  alias Plenario.Actions.UserActions

  def index(conn, _) do
    users = UserActions.list()
    render(conn, "index.html", users: users)
  end

  def edit(conn, %{"id" => id}) do
    user = UserActions.get(id)
    changeset = UserActions.edit(user)
    action = user_path(conn, :update, id)
    render(conn, "edit.html", user: user, changeset: changeset, action: action)
  end

  def update(conn, %{"id" => id, "user" => %{"name" => name, "email" => email, "bio" => bio}}) do
    user = UserActions.get(id)
    case UserActions.update(user, name: name, email: email, bio: bio) do
      {:ok, user} ->
        conn
        |> put_flash(:success, "#{user.name} updated.")
        |> redirect(to: user_path(conn, :index))

      {:error, changeset} ->
        action = user_path(conn, :update, id)
        conn
        |> put_flash(:error, "Please review errors below.")
        |> put_status(:bad_request)
        |> render("edit.html", user: user, changeset: changeset, action: action)
    end
  end

  def strip_admin_privs(conn, %{"id" => id}) do
    user = UserActions.get(id)
    case UserActions.strip_admin_privs(user) do
      {:ok, user} ->
        conn
        |> put_flash(:success, "#{user.name} was stripped of admin privs.")
        |> redirect(to: user_path(conn, :index))

      {:error, changeset} ->
        Enum.each(changeset.errors, fn e -> put_flash(conn, :error, e.message) end)
        conn
        |> put_status(:bad_request)
        |> redirect(to: user_path(conn, :index))
    end
  end

  def promote_to_admin(conn, %{"id" => id}) do
    user = UserActions.get(id)
    case UserActions.promote_to_admin(user) do
      {:ok, user} ->
        conn
        |> put_flash(:success, "#{user.name} was promoted to admin.")
        |> redirect(to: user_path(conn, :index))

      {:error, changeset} ->
        Enum.each(changeset.errors, fn e -> put_flash(conn, :error, e.message) end)
        conn
        |> put_status(:bad_request)
        |> redirect(to: user_path(conn, :index))
    end
  end

  def archive(conn, %{"id" => id}) do
    user = UserActions.get(id)
    case UserActions.archive(user) do
      {:ok, user} ->
        conn
        |> put_flash(:success, "#{user.name} was archived.")
        |> redirect(to: user_path(conn, :index))

      {:error, changeset} ->
        Enum.each(changeset.errors, fn e -> put_flash(conn, :error, e.message) end)
        conn
        |> put_status(:bad_request)
        |> redirect(to: user_path(conn, :index))
    end
  end

  def activate(conn, %{"id" => id}) do
    user = UserActions.get(id)
    case UserActions.activate(user) do
      {:ok, user} ->
        conn
        |> put_flash(:success, "#{user.name} was activated.")
        |> redirect(to: user_path(conn, :index))

      {:error, changeset} ->
        Enum.each(changeset.errors, fn e -> put_flash(conn, :error, e.message) end)
        conn
        |> put_status(:bad_request)
        |> redirect(to: user_path(conn, :index))
    end
  end
end
