defmodule Plenario2Web.AdminController do
  use Plenario2Web, :controller
  import Plenario2.Queries.Utils
  alias Plenario2Auth.UserActions
  alias Plenario2Auth.UserQueries, as: Q
  alias Plenario2.Repo

  def index(conn, _) do
    render(conn, "index.html")
  end

  def user_index(conn, params) do
    users = Q.list()
    |> cond_compose(Map.get(params, "active", false), Q, :active)
    |> cond_compose(Map.get(params, "archived", false), Q, :archived)
    |> cond_compose(Map.get(params, "trusted", false), Q, :trusted)
    |> cond_compose(Map.get(params, "admin", false), Q, :admin)
    |> Repo.all()

    render(conn, "user_list.html", users: users)
  end

  def archive_user(conn, %{"user_id" => user_id}) do
    UserActions.get_from_pk(user_id)
    |> UserActions.archive()

    conn
    |> put_flash(:success, "Archived user")
    |> redirect(to: admin_path(conn, :user_index))
  end

  def activate_user(conn, %{"user_id" => user_id}) do
    UserActions.get_from_pk(user_id)
    |> UserActions.activate()

    conn
    |> put_flash(:success, "Activated user")
    |> redirect(to: admin_path(conn, :user_index))
  end

  def trust_user(conn, %{"user_id" => user_id}) do
    UserActions.get_from_pk(user_id)
    |> UserActions.trust()

    conn
    |> put_flash(:success, "Trusted user")
    |> redirect(to: admin_path(conn, :user_index))
  end

  def untrust_user(conn, %{"user_id" => user_id}) do
    UserActions.get_from_pk(user_id)
    |> UserActions.untrust()

    conn
    |> put_flash(:success, "Untrusted user")
    |> redirect(to: admin_path(conn, :user_index))
  end

  def promote_to_admin(conn, %{"user_id" => user_id}) do
    UserActions.get_from_pk(user_id)
    |> UserActions.promote_to_admin()

    conn
    |> put_flash(:success, "Promoted user to admin")
    |> redirect(to: admin_path(conn, :user_index))
  end

  def strip_admin_privs(conn, %{"user_id" => user_id}) do
    UserActions.get_from_pk(user_id)
    |> UserActions.strip_admin()

    conn
    |> put_flash(:success, "Stripped user of admin privileges")
    |> redirect(to: admin_path(conn, :user_index))
  end
end
