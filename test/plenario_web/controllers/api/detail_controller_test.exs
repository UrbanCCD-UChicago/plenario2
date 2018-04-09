defmodule PlenarioWeb.Api.DetailControllerTest do
  use PlenarioWeb.Testing.ConnCase

  test "OPTIONS /api/v2/detail status", %{conn: conn} do
    conn = options(conn, "/api/v2/detail")
    assert conn.status == 204
  end

  test "OPTIONS /api/v2/detail headers", %{conn: conn} do
    conn = options(conn, "/api/v2/detail")
    headers = Enum.into(conn.resp_headers, %{})
    assert headers["access-control-allow-methods"] == "GET,HEAD,OPTIONS"
    assert headers["access-control-allow-origin"] == "*"
    assert headers["access-control-max-age"] == "300"
  end
end
