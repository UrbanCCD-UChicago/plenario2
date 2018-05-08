defmodule PlenarioWeb.Api.DetailControllerTest do
  use PlenarioWeb.Testing.ConnCase

  alias Plenario.{ModelRegistry, Repo}
  alias Plenario.Actions.{
    DataSetActions,
    DataSetFieldActions,
    MetaActions,
    UniqueConstraintActions,
    UserActions
  }

  setup do
    Ecto.Adapters.SQL.Sandbox.checkout(Plenario.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Plenario.Repo, {:shared, self()})

    {:ok, user} = UserActions.create("API Test User", "test@example.com", "password")
    {:ok, meta} = MetaActions.create("API Test Dataset", user.id, "https://www.example.com", "csv")
    {:ok, pk} = DataSetFieldActions.create(meta.id, "pk", "integer")
    {:ok, _} = DataSetFieldActions.create(meta.id, "datetime", "timestamptz")
    {:ok, _} = DataSetFieldActions.create(meta.id, "location", "text")
    {:ok, _} = DataSetFieldActions.create(meta.id, "data", "text")
    {:ok, _} = UniqueConstraintActions.create(meta.id, [pk.id])

    DataSetActions.up!(meta)

    # Insert 100 empty rows
    ModelRegistry.clear()
    model = ModelRegistry.lookup(meta.slug())
    (1..100) |> Enum.each(fn _ -> Repo.insert(model.__struct__) end)

    %{slug: meta.slug()}
  end

  test "GET /api/v2/data-sets/:slug", %{slug: slug} do
    conn = get(build_conn(), "/api/v2/data-sets/#{slug}")
    response = json_response(conn, 200)
    assert length(response["data"]) == 100
  end

  test "GET /api/v2/data-sets/:slug/@head", %{slug: slug} do
    conn = get(build_conn(), "/api/v2/data-sets/#{slug}/@head")
    response = json_response(conn, 200)
    assert is_map(response["data"])
  end

  test "GET /api/v2/data-sets/:slug/@describe", %{slug: slug} do
    conn = get(build_conn(), "/api/v2/data-sets/#{slug}/@describe")
    response = json_response(conn, 200)
    assert length(response["data"]) == 100
  end

  test "GET /api/v2/data-sets/:slug pagination page parameter", %{slug: slug} do
    conn = get(build_conn(), "/api/v2/data-sets/#{slug}?page=2")
    response = json_response(conn, 200)
    assert length(response["data"]) == 0
    assert response["meta"]["counts"]["total_pages"] == 1
  end

  test "GET /api/v2/data-sets/:slug pagination page_size parameter", %{slug: slug} do
    conn = get(build_conn(), "/api/v2/data-sets/#{slug}?page_size=10")
    response = json_response(conn, 200)
    assert length(response["data"]) == 10
    assert response["meta"]["counts"]["total_pages"] == 10
  end

  test "GET /api/v2/data-sets/:slug pagination page and page_size parameters", %{slug: slug} do
    conn = get(build_conn(), "/api/v2/data-sets/#{slug}?page_size=5&page=2")
    response = json_response(conn, 200)
    assert length(response["data"]) == 5
    assert response["meta"]["params"]["page"] == "2"
    assert response["meta"]["params"]["page_size"] == "5"
  end

  test "GET /api/v2/data-sets/:slug pagination is stable with backfills", %{slug: slug} do
    conn = get(build_conn(), "/api/v2/data-sets/#{slug}?page_size=5&page=2")
    response = json_response(conn, 200)

    assert length(response["data"]) == 5
    assert response["meta"]["params"]["page"] == "2"
    assert response["meta"]["params"]["page_size"] == "5"
  end

  test "GET /api/v2/data-sets/:slug populates pagination links", %{slug: slug} do
    conn = get(build_conn(), "/api/v2/data-sets/#{slug}?page_size=5&page=2")
    response = json_response(conn, 200)

    assert length(response["data"]) == 5
    assert response["meta"]["links"]["current"] =~ "page_size=5&page=2"
    assert response["meta"]["links"]["current"] =~ "inserted_at"
    assert response["meta"]["links"]["previous"] =~ "page_size=5&page=1"
    assert response["meta"]["links"]["previous"] =~ "inserted_at"
    assert response["meta"]["links"]["next"] =~ "page_size=5&page=3"
    assert response["meta"]["links"]["next"] =~ "inserted_at"
  end

  test "OPTIONS /api/v2/data-sets/:slug status", %{conn: conn} do
    conn = options(conn, "/api/v2/data-sets")
    assert conn.status == 204
  end

  test "OPTIONS /api/v2/data-sets/:slug headers", %{conn: conn} do
    conn = options(conn, "/api/v2/data-sets")
    headers = Enum.into(conn.resp_headers, %{})
    assert headers["access-control-allow-methods"] == "GET,HEAD,OPTIONS"
    assert headers["access-control-allow-origin"] == "*"
    assert headers["access-control-max-age"] == "300"
  end

  test "GET /api/v2/data-sets/:slug bbox query", %{conn: conn, slug: slug} do
    conn = get(build_conn(), "/api/v2/data-sets/#{slug}?bbox=#{geojson}")

  end

  test "GET /api/v2/data-sets/:slug range query", %{conn: conn, slug: slug} do
    conn = get(build_conn(), "/api/v2/data-sets/#{slug}?datetime={\"upper\": \"2000-01-01\", \"lower\": \"3000-01-01\"}")
  end

  test "GET /api/v2/data-sets/:slug location query", %{conn: conn, slug: slug} do
    conn = get(build_conn(), "/api/v2/data-sets/#{slug}?page_size=5&page=2")

  end
end
