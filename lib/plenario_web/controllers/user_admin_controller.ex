defmodule PlenarioWeb.UserAdminController do
  use PlenarioWeb, :controller

  alias Plenario.{
    User,
    UserActions
  }

  def index(conn, _) do
    users = UserActions.list()

    admins = Enum.filter(users, & &1.is_admin?)
    regulars = Enum.reject(users, & &1.is_admin?)

    render conn, "index.html",
      admins: admins,
      regulars: regulars
  end

  def edit(conn, %{"id" => id}) do
    user = UserActions.get!(id)
    changeset = User.changeset(user, %{})

    update_action = Routes.user_admin_path(conn, :update, user)
    cancel_action = Routes.user_admin_path(conn, :index)

    render conn, "edit.html",
      user: user,
      changeset: changeset,
      update_action: update_action,
      cancel_action: cancel_action
  end

  def update(conn, %{"id" => id, "user" => form}) do
    user = UserActions.get!(id)

    UserActions.update(user, form)
    |> do_update(conn, user)
  end

  defp do_update({:ok, user}, conn, _) do
    conn
    |> put_flash(:success, "Updated #{user.username}")
    |> redirect(to: Routes.user_admin_path(conn, :index))
  end

  defp do_update({:error, changeset}, conn, user) do
    update_action = Routes.user_admin_path(conn, :update, user)
    cancel_action = Routes.user_admin_path(conn, :index)

    conn
    |> put_status(:bad_request)
    |> put_error_flashes(changeset)
    |> render("edit.html",
      user: user,
      changeset: changeset,
      update_action: update_action,
      cancel_action: cancel_action
    )
  end
end
