defmodule PlenarioWeb.Web.Testing.AdminUserNoteControllerTest do
  use PlenarioWeb.Testing.ConnCase 

  alias Plenario.Actions.MetaActions

  alias PlenarioMailer.Actions.AdminUserNoteActions

  setup %{admin_user: admin, reg_user: user} do
    {:ok, meta} = MetaActions.create("name", user, "https://example.com/", "csv")
    {:ok, note} = AdminUserNoteActions.create_for_meta(meta, admin, user, "this is a test", false)
    {:ok, [note: note]}
  end

  @tag :auth
  test "mark acknowledged", %{conn: conn, note: note} do
    conn
    |> post(admin_user_note_path(conn, :mark_acknowledged, note.id, redir: me_path(conn, :index)))
    |> html_response(:found)

    note = AdminUserNoteActions.get(note.id)
    assert note.acknowledged
  end
end
