defmodule PlenarioWeb.AdminController do
  use PlenarioWeb, :controller

  import Plenario.Queries.Utils

  alias Plenario.Actions.{MetaActions, UserActions}
  alias Plenario.Queries.UserQueries, as: UserQ
  alias Plenario.Repo

  alias PlenarioMailer.Actions.AdminUserNoteActions

  require Logger

  def index(conn, _) do
    render(conn, "index.html")
  end

  ##
  # users

  def user_index(conn, params) do
    users =
      UserQ.list()
      |> bool_compose(Map.get(params, "active", false), UserQ, :active)
      |> bool_compose(Map.get(params, "archived", false), UserQ, :archived)
      |> bool_compose(Map.get(params, "trusted", false), UserQ, :trusted)
      |> bool_compose(Map.get(params, "admin", false), UserQ, :admin)
      |> Repo.all()

    render(conn, "user_list.html", users: users)
  end

  def archive_user(conn, %{"user_id" => user_id}) do
    UserActions.get(user_id)
    |> UserActions.archive()

    Logger.info("Archived user #{user_id}")

    conn
    |> put_flash(:success, "Archived user")
    |> redirect(to: admin_path(conn, :user_index))
  end

  def activate_user(conn, %{"user_id" => user_id}) do
    UserActions.get(user_id)
    |> UserActions.activate()

    Logger.info("Activated user #{user_id}")

    conn
    |> put_flash(:success, "Activated user")
    |> redirect(to: admin_path(conn, :user_index))
  end

  def promote_to_admin(conn, %{"user_id" => user_id}) do
    UserActions.get(user_id)
    |> UserActions.promote_to_admin()

    Logger.info("User #{user_id} promoted to admin")

    conn
    |> put_flash(:success, "Promoted user to admin")
    |> redirect(to: admin_path(conn, :user_index))
  end

  def strip_admin_privs(conn, %{"user_id" => user_id}) do
    UserActions.get(user_id)
    |> UserActions.strip_admin_privs()

    Logger.info("User #{user_id} stripped of Admin")

    conn
    |> put_flash(:success, "Stripped user of admin privileges")
    |> redirect(to: admin_path(conn, :user_index))
  end

  ##
  # metas

  def meta_index(conn, _) do
    all_metas = MetaActions.list(with_user: true)
    ready_metas = Enum.filter(all_metas, fn m -> m.state == "ready" end)
    erred_metas = Enum.filter(all_metas, fn m -> m.state == "erred" end)
    approval_metas = Enum.filter(all_metas, fn m -> m.state == "needs_approval" end)
    new_metas = Enum.filter(all_metas, fn m -> m.state == "new" end)

    render(
      conn,
      "meta_index.html",
      all_metas: all_metas,
      ready_metas: ready_metas,
      erred_metas: erred_metas,
      approval_metas: approval_metas,
      new_metas: new_metas
    )
  end

  def get_meta_approval_review(conn, %{"id" => meta_id}) do
    meta = MetaActions.get(meta_id, with_user: true, with_fields: true, with_constraints: true)
    approve_action = admin_path(conn, :approve_meta, meta_id)
    disapprove_action = admin_path(conn, :disapprove_meta, meta_id)

    render(
      conn,
      "meta_approval_review.html",
      meta: meta,
      approve_action: approve_action,
      disapprove_action: disapprove_action
    )
  end

  def approve_meta(conn, %{"id" => meta_id}) do
    meta = MetaActions.get(meta_id, with_user: true)
    {:ok, _} = MetaActions.approve(meta)

    conn
    |> put_flash(:success, "'#{meta.name}' marked as approved")
    |> redirect(to: admin_path(conn, :meta_index))
  end

  def disapprove_meta(conn, %{"id" => meta_id, "message" => message}) do
    meta = MetaActions.get(meta_id, with_user: true)
    admin = Guardian.Plug.current_resource(conn)

    {:ok, _} = MetaActions.disapprove(meta)
    {:ok, _} = AdminUserNoteActions.create_for_meta(message, admin, meta.user, false)

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
