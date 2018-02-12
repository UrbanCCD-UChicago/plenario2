defmodule PlenarioWeb.Admin.Testing.MetaControllerTest do
  use PlenarioWeb.Testing.ConnCase, async: true

  alias Plenario.Actions.MetaActions

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

    conn
    |> post(meta_path(conn, :approve, meta.id))
    |> html_response(:found)

    meta = MetaActions.get(meta.id)
    assert meta.state == "awaiting_first_import"
  end

  @tag :admin
  test "disapprove", %{conn: conn, meta: meta} do
    {:ok, _} = MetaActions.submit_for_approval(meta)

    conn
    |> post(meta_path(conn, :disapprove, meta.id))
    |> html_response(:found)

    meta = MetaActions.get(meta.id)
    assert meta.state == "new"
  end
end
