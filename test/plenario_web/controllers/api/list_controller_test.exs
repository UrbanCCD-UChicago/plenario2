defmodule PlenarioWeb.Api.ListControllerTest do
  use PlenarioWeb.Testing.ConnCase

  alias Plenario.Actions.{MetaActions, UserActions}

  setup do
    Ecto.Adapters.SQL.Sandbox.checkout(Plenario.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Plenario.Repo, {:shared, self()})

    {:ok, user} = UserActions.create("API Test User", "test@example.com", "password")
    {:ok, _} = MetaActions.create("API Test Dataset", user.id, "https://www.example.com", "csv")
    {:ok, _} = MetaActions.create("API Test Dataset 2", user.id, "https://www.example.com/2", "csv")
    {:ok, _} = MetaActions.create("API Test Dataset 3", user.id, "https://www.example.com/3", "csv")
    {:ok, _} = MetaActions.create("API Test Dataset 4", user.id, "https://www.example.com/4", "csv")
    {:ok, _} = MetaActions.create("API Test Dataset 5", user.id, "https://www.example.com/5", "csv")

    :ok
  end

  test "GET /api/v2/data-sets", %{conn: conn} do
    conn = get(conn, "/api/v2/data-sets")
    result = json_response(conn, 200)
    assert length(result["data"]) == 5
  end

  test "GET /api/v2/data-sets/@head", %{conn: conn} do
    conn = get(conn, "/api/v2/data-sets/@head")
    result = json_response(conn, 200)
    assert is_map(result["data"])
  end

  test "GET /api/v2/data-sets/@describe", %{conn: conn} do
    conn = get(conn, "/api/v2/data-sets/@describe")
    result = json_response(conn, 200)
    assert length(result["data"]) == 5
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

  test "POST api/v2/data-sets status", %{conn: conn} do
    conn = post(conn, "/api/v2/data-sets")
    assert conn.status == 405
  end

  test "PUT /api/v2/data-sets status", %{conn: conn} do
    conn = put(conn, "/api/v2/data-sets")
    assert conn.status == 405
  end

  test "PATCH /api/v2/data-sets status", %{conn: conn} do
    conn = patch(conn, "/api/v2/data-sets")
    assert conn.status == 405
  end

  test "DELETE /api/v2/data-sets status", %{conn: conn} do
    conn = delete(conn, "/api/v2/data-sets")
    assert conn.status == 405
  end

  test "TRACE /api/v2/data-sets status", %{conn: conn} do
    conn = trace(conn, "/api/v2/data-sets")
    assert conn.status == 405
  end

  test "CONNECT /api/v2/data-sets status", %{conn: conn} do
    conn = connect(conn, "/api/v2/data-sets")
    assert conn.status == 405
  end

end
