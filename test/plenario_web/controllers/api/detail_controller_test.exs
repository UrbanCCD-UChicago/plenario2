defmodule PlenarioWeb.Api.DetailControllerTest do
  use PlenarioWeb.Testing.ConnCase

  test "GET /api/v2/detail", %{conn: conn} do
    conn = get(conn, "/api/v2/detail")
    assert json_response(conn, 200) == %{}
  end

  test "GET /api/v2/detail/@head", %{conn: conn} do
    conn = get(conn, "/api/v2/detail/@head")
    assert json_response(conn, 200) == %{}
  end

  test "GET /api/v2/detail/@describe", %{conn: conn} do
    conn = get(conn, "/api/v2/detail/@describe")
    assert json_response(conn, 200) == %{}
  end
end
