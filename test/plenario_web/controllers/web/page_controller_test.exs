defmodule PlenarioWeb.Web.Testing.PageControllerTest do
  use PlenarioWeb.Testing.ConnCase, async: true

  @tag :anon
  test "index", %{conn: conn} do
    conn
    |> get(page_path(conn, :index))
    |> html_response(:ok)
  end

  @tag :anon
  test "explorer", %{conn: conn} do
    conn
    |> get(page_path(conn, :explorer))
    |> html_response(:ok)
  end

  @tag :anon
  test "aot_explorer", %{conn: conn} do
    conn
    |> get(page_path(conn, :aot_explorer))
    |> html_response(:ok)
  end
end
