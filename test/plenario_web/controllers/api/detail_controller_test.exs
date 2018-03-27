defmodule PlenarioWeb.Api.DetailControllerTest do
  use PlenarioWeb.Testing.ConnCase

  test "GET /api/v2/detail", %{conn: conn} do
    conn = get(conn, "/api/v2/detail")
    assert json_response(conn, 200) == %{}
  end

  test "HEAD /api/v2/detail", %{conn: conn} do
    conn = head(conn, "/api/v2/detail")
    assert json_response(conn, 200) == %{}
  end

  test "OPTIONS /api/v2/detail", %{conn: conn} do
    conn = options(conn, "/api/v2/detail")
    assert json_response(conn, 200) == %{}
  end
end
