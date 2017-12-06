defmodule Plenario2Web.AdminUserNoteControllerTest do
  use Plenario2Web.ConnCase, async: true

  alias Plenario2.Actions.{MetaActions, AdminUserNoteActions}
  alias Plenario2Auth.UserActions

  test "POST /acknowledge", %{conn: conn} do
    {:ok, admin} = UserActions.create("Admin", "password", "admin@exmaple.com")
    admin = UserActions.get_from_id(admin.id)
    UserActions.promote_to_admin(admin)

    {:ok, regular} = UserActions.create("Regular", "password", "regular@exmaple.com")
    regular = UserActions.get_from_id(regular.id)

    {:ok, meta} = MetaActions.create("test", regular.id, "https://example.com/")
    meta = MetaActions.get_from_id(meta.id)

    {:ok, note} = AdminUserNoteActions.create_for_meta("blah blah blah", admin, regular, meta)

    conn = post(conn, auth_path(conn, :do_login, %{"user" => %{"email_address" => regular.email_address, "plaintext_password" => "password"}}))
    response = conn
      |> post(admin_user_note_path(conn, :acknowledge, note.id), %{"path" => meta_path(conn, :detail, meta.slug)})
      |> html_response(:found)

    refute response =~ "blah blah blah"
  end
end
