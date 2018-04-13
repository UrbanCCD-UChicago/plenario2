defmodule PlenarioWeb.Controllers.Web.ExportControllerTest do
  use Plenario.Testing.DataCase
  alias Plenario.Actions.UserActions
  alias Plenario.Schemas.User

  setup do
    %{conn: build_conn()}
  end

  test "export_meta/2 without being signed in", %{conn: conn, meta: meta} do
    path = export_path(conn, :export_meta, meta.id)

    conn
    |> post(path)
    |> redirected_to(302)
  end

  test "export_meta/2 signed in", %{conn: conn, meta: meta} do
    {:ok, user} = UserActions.create("username", "user@email.com", "password")
    conn = assign(conn, :current_user, user)
    path = export_path(conn, :export_meta, meta.id)

    conn
    |> post(path)
    |> IO.inspect
  end
end
