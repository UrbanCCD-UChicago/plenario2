defmodule Plenario2Web.AdminController do
  use Plenario2Web, :controller

  import Plenario2.Queries.Utils

  alias Plenario2Auth.UserActions
  alias Plenario2Auth.UserQueries, as: UserQ

  alias Plenario2.Actions.MetaActions
  alias Plenario2.Repo

  def index(conn, _) do
    render(conn, "index.html")
  end

  ##
  # users

  def user_index(conn, params) do
    users = UserQ.list()
    |> cond_compose(Map.get(params, "active", false), UserQ, :active)
    |> cond_compose(Map.get(params, "archived", false), UserQ, :archived)
    |> cond_compose(Map.get(params, "trusted", false), UserQ, :trusted)
    |> cond_compose(Map.get(params, "admin", false), UserQ, :admin)
    |> Repo.all()

    render(conn, "user_list.html", users: users)
  end

  def archive_user(conn, %{"user_id" => user_id}) do
    UserActions.get_from_id(user_id)
    |> UserActions.archive()

    conn
    |> put_flash(:success, "Archived user")
    |> redirect(to: admin_path(conn, :user_index))
  end

  def activate_user(conn, %{"user_id" => user_id}) do
    UserActions.get_from_id(user_id)
    |> UserActions.activate()

    conn
    |> put_flash(:success, "Activated user")
    |> redirect(to: admin_path(conn, :user_index))
  end

  def trust_user(conn, %{"user_id" => user_id}) do
    UserActions.get_from_id(user_id)
    |> UserActions.trust()

    conn
    |> put_flash(:success, "Trusted user")
    |> redirect(to: admin_path(conn, :user_index))
  end

  def untrust_user(conn, %{"user_id" => user_id}) do
    UserActions.get_from_id(user_id)
    |> UserActions.untrust()

    conn
    |> put_flash(:success, "Untrusted user")
    |> redirect(to: admin_path(conn, :user_index))
  end

  def promote_to_admin(conn, %{"user_id" => user_id}) do
    UserActions.get_from_id(user_id)
    |> UserActions.promote_to_admin()

    conn
    |> put_flash(:success, "Promoted user to admin")
    |> redirect(to: admin_path(conn, :user_index))
  end

  def strip_admin_privs(conn, %{"user_id" => user_id}) do
    UserActions.get_from_id(user_id)
    |> UserActions.strip_admin()

    conn
    |> put_flash(:success, "Stripped user of admin privileges")
    |> redirect(to: admin_path(conn, :user_index))
  end

  ##
  # metas

  def meta_index(conn, _) do
    all_metas = MetaActions.list([with_user: true])
    ready_metas = Enum.filter(all_metas, fn m -> m.state == "ready" end)
    erred_metas = Enum.filter(all_metas, fn m -> m.state == "erred" end)
    approval_metas = Enum.filter(all_metas, fn m -> m.state == "needs_approval" end)
    new_metas = Enum.filter(all_metas, fn m -> m.state == "new" end)

    render(conn, "meta_index.html",
      all_metas: all_metas, ready_metas: ready_metas,
      erred_metas: erred_metas, approval_metas: approval_metas,
      new_metas: new_metas)
  end

  def get_meta_approval_review(conn, %{"id" => meta_id}) do
    meta = MetaActions.get(meta_id, [with_user: true, with_fields: true, with_constraints: true])
    approve_action = admin_path(conn, :approve_meta, meta_id)
    disapprove_action = admin_path(conn, :disapprove_meta, meta_id)

    render(conn, "meta_approval_review.html",
      meta: meta, approve_action: approve_action,
      disapprove_action: disapprove_action)
  end

  def approve_meta(conn, %{"id" => meta_id}) do
    meta = MetaActions.get(meta_id, [with_user: true])
    admin = Guardian.Plug.current_resource(conn)

    {:ok, _} = MetaActions.approve(meta, admin)

    conn
    |> put_flash(:success, "'#{meta.name}' marked as approved")
    |> redirect(to: admin_path(conn, :meta_index))
  end

  def disapprove_meta(conn, %{"id" => meta_id, "message" => message}) do
    meta = MetaActions.get(meta_id, [with_user: true])
    admin = Guardian.Plug.current_resource(conn)

    {:ok, _} = MetaActions.disapprove(meta, admin, message)

    conn
    |> put_flash(:success, "'#{meta.name}' marked as disapproved")
    |> redirect(to: admin_path(conn, :meta_index))
  end

  # def mark_meta_erred(conn, %{"id" => meta_id, "message" => message}) do
  #   meta = MetaActions.get(meta_id, [with_user: true])
  #   admin = Guardian.Plug.current_resource(conn)
  #
  #   {:ok, _} = MetaActions.mark_erred(meta, admin, message)
  #
  #   conn
  #   |> put_flash(:success, "'#{meta.name}' marked as erred")
  #   |> redirect(to: admin_path(conn, :meta_index))
  # end

  # def mark_meta_fixed(conn, %{"id" => meta_id, "message" => message}) do
  #   meta = MetaActions.get(meta_id, [with_user: true])
  #   admin = Guardian.Plug.current_resource(conn)
  #
  #   {:ok, _} = MetaActions.mark_fixed(meta, admin, message)
  #
  #   conn
  #   |> put_flash(:success, "'#{meta.name}' marked as fixed")
  #   |> redirect(to: admin_path(conn, :meta_index))
  # end
end
