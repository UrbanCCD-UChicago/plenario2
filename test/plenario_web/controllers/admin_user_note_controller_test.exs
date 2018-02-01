# defmodule PlenarioWeb.AdminUserNoteControllerTest do
#   use PlenarioWeb.ConnCase, async: true
#
#   alias Plenario.Actions.{MetaActions, AdminUserNoteActions}
#
#   @tag :auth
#   test "POST /acknowledge", %{conn: conn, admin_user: admin, reg_user: regular} do
#     {:ok, meta} = MetaActions.create("test", regular.id, "https://example.com/")
#     meta = MetaActions.get(meta.id)
#
#     {:ok, note} = AdminUserNoteActions.create_for_meta("blah blah blah", admin, regular, meta)
#
#     conn
#     |> post(admin_user_note_path(conn, :acknowledge, note.id), %{
#       "path" => meta_path(conn, :detail, meta.slug)
#     })
#     |> html_response(:found)
#
#     note = AdminUserNoteActions.get(note.id)
#     assert note.acknowledged == true
#   end
# end
