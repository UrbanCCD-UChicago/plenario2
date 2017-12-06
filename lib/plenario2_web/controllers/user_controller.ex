defmodule Plenario2Web.UserController do
  use Plenario2Web, :controller

  alias Plenario2.Actions.{MetaActions, AdminUserNoteActions}
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
end
