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

  test "OPTIONS /api/v2/data-sets status", %{conn: conn} do
    conn = options(conn, "/api/v2/data-sets")
    assert conn.status == 204
  end

  test "OPTIONS /api/v2/data-sets headers", %{conn: conn} do
    conn = options(conn, "/api/v2/data-sets")
    headers = Enum.into(conn.resp_headers, %{})
    assert headers["access-control-allow-methods"] == "GET,HEAD,OPTIONS"
    assert headers["access-control-allow-origin"] == "*"
    assert headers["access-control-max-age"] == "300"
  end
end
