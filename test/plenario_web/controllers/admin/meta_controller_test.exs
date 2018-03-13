defmodule PlenarioWeb.Admin.Testing.MetaControllerTest do
  use PlenarioWeb.Testing.ConnCase 

  alias Plenario.Actions.MetaActions

  alias PlenarioMailer.Actions.AdminUserNoteActions

  setup %{admin_user: user} do
    {:ok, meta} = MetaActions.create("name", user, "https://example.com/", "csv")

    {:ok, [meta: meta]}
  end

  @tag :admin
  test "index", %{conn: conn} do
    response =
      conn
      |> get(meta_path(conn, :index))
      |> html_response(:ok)

    MetaActions.list()
    |> Enum.each(fn m -> assert response =~ m.name end)
  end

  @tag :admin
  test "review", %{conn: conn, meta: meta} do
    conn
    |> get(meta_path(conn, :review, meta.id))
    |> html_response(:ok)
  end

  @tag :admin
  test "approve", %{conn: conn, meta: meta} do
    {:ok, _} = MetaActions.submit_for_approval(meta)

    notes = AdminUserNoteActions.list(for_meta: meta)
    assert length(notes) == 0

    conn
    |> post(meta_path(conn, :approve, meta.id))
    |> html_response(:found)

    meta = MetaActions.get(meta.id)
    assert meta.state == "awaiting_first_import"

    notes = AdminUserNoteActions.list(for_meta: meta)
    assert length(notes) == 1
  end

  @tag :admin
  test "disapprove", %{conn: conn, meta: meta} do
    {:ok, _} = MetaActions.submit_for_approval(meta)

    notes = AdminUserNoteActions.list(for_meta: meta)
    assert length(notes) == 0

    conn
    |> post(meta_path(conn, :disapprove, meta.id))
    |> html_response(:found)

    meta = MetaActions.get(meta.id)
    assert meta.state == "new"

    notes = AdminUserNoteActions.list(for_meta: meta)
    assert length(notes) == 1
  end
end
