defmodule PlenarioWeb.Api.AotControllerTest do
  use PlenarioWeb.Testing.ConnCase

  test "GET /api/v2/aot", %{conn: conn} do
    conn = get(conn, "/api/v2/aot")
    assert json_response(conn, 200) == %{}
  end

  test "HEAD /api/v2/aot", %{conn: conn} do
    conn = head(conn, "/api/v2/aot")
    assert json_response(conn, 200) == %{}
  end

  test "OPTIONS /api/v2/aot", %{conn: conn} do
    conn = options(conn, "/api/v2/aot")
    assert json_response(conn, 200) == %{}
  end
end
