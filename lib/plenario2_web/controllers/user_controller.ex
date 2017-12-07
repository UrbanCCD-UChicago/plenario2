defmodule Plenario2Web.UserController do
  use Plenario2Web, :controller

  alias Plenario2.Actions.{MetaActions, AdminUserNoteActions}
  alias Plenario2Auth.{UserActions, UserChangesets}
  alias Plenario2.Repo

  def index(conn, _) do
    user = Guardian.Plug.current_resource(conn)

    unread_notes = AdminUserNoteActions.list([unread: true, for_user: user])
    archived_notes = AdminUserNoteActions.list([acknowledged: true, for_user: user, oldest_first: true])

    new = MetaActions.list([for_user: user, new: true])
    awaiting = MetaActions.list([for_user: user, needs_approval: true])
    ready = MetaActions.list([for_user: user, ready: true, limit_to: 3])
    erred = MetaActions.list([for_user: user, erred: true])

    conn
    |> render(
      "index.html",
      unread_notes: unread_notes,
      archived_notes: archived_notes,
      new_metas: new,
      awaiting_metas: awaiting,
      ready_metas: ready,
      erred_metas: erred
    )
  end

  def get_update_name(conn, _) do
    user = Guardian.Plug.current_resource(conn)
    changeset = UserChangesets.update_name(user, %{})
    action = user_path(conn, :do_update_name)

    render(conn, "update_name.html", changeset: changeset, action: action)
  end

  def do_update_name(conn, %{"user" => %{"name" => name}}) do
    user = Guardian.Plug.current_resource(conn)

    UserActions.update_name(user, name)
    |> update_name_reply(conn)
  end

  defp update_name_reply({:ok, user}, conn) do
    conn
    |> put_flash(:success, "Your name has been updated")
    |> redirect(to: user_path(conn, :index))
  end

  defp update_name_reply({:error, changeset}, conn) do
    action = user_path(conn, :do_update_name)

    conn
    |> put_flash(:error, "Please review and fix errors below")
    |> put_status(:bad_request)
    |> render("update_name.html", changeset: changeset, action: action)
  end
end
