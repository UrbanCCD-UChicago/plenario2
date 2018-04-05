defmodule PlenarioWeb.Api.ListControllerTest do
  use PlenarioWeb.Testing.ConnCase

  test "GET /api/v2/data-sets", %{conn: conn} do
    conn = get(conn, "/api/v2/data-sets")
    result = json_response(conn, 200)
    assert result["data"] == []
  end

  test "GET /api/v2/data-sets/@head", %{conn: conn} do
    conn = get(conn, "/api/v2/data-sets")
    result = json_response(conn, 200)
    assert result["data"] == []
  end

  test "GET /api/v2/data-sets/@describe", %{conn: conn} do
    conn = get(conn, "/api/v2/data-sets")
    result = json_response(conn, 200)
    assert result["data"] == []
  end
end
