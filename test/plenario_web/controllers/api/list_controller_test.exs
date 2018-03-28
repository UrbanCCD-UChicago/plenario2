defmodule PlenarioWeb.Api.ListControllerTest do
  use PlenarioWeb.Testing.ConnCase

  test "GET /api/v2/data-sets", %{conn: conn} do
    conn = get(conn, "/api/v2/data-sets")
    assert json_response(conn, 200) == %{}
  end

  test "GET /api/v2/data-sets/@head", %{conn: conn} do
    conn = get(conn, "/api/v2/data-sets")
    assert json_response(conn, 200) == %{}
  end

  test "GET /api/v2/data-sets/@describe", %{conn: conn} do
    conn = get(conn, "/api/v2/data-sets")
    assert json_response(conn, 200) == %{}
  end
end
