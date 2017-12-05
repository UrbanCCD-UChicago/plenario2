defmodule Plenario2Web.PageControllerTest do
  use Plenario2Web.ConnCase, async: true

  test "GET /", %{conn: conn} do
    response =
      conn
      |> get(page_path(conn, :index))
      |> html_response(200)

    assert response =~ "Home Page"
  end
end
