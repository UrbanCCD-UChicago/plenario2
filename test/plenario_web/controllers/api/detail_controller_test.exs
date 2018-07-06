defmodule PlenarioWeb.Api.DetailControllerTest do
  use ExUnit.Case
  use Phoenix.ConnTest

  @endpoint PlenarioWeb.Endpoint

  alias Plenario.{ModelRegistry, Repo}
  alias Plenario.Actions.{
    DataSetActions,
    DataSetFieldActions,
    MetaActions,
    UserActions,
    VirtualPointFieldActions
  }

  setup do
    Ecto.Adapters.SQL.Sandbox.checkout(Plenario.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Plenario.Repo, {:shared, self()})

    {:ok, user} = UserActions.create("API Test User", "test@example.com", "password")
    {:ok, meta} = MetaActions.create("API Test Dataset", user.id, "https://www.example.com", "csv")
    {:ok, _} = DataSetFieldActions.create(meta.id, "pk", "integer")
    {:ok, _} = DataSetFieldActions.create(meta.id, "datetime", "timestamp")
    {:ok, _} = DataSetFieldActions.create(meta.id, "data", "text")
    {:ok, location} = DataSetFieldActions.create(meta.id, "location", "text")
    {:ok, vpf} = VirtualPointFieldActions.create(meta, location.id)

    DataSetActions.up!(meta)

    ModelRegistry.clear()

    insert = """
    INSERT INTO "#{meta.table_name}"
      (pk, datetime, data, location)
    VALUES
      (1, '2000-01-01 00:00:00', null, null),
      (2, '2000-01-01 00:00:00', null, null),
      (3, '2000-01-01 00:00:00', null, null),
      (4, '2000-01-01 00:00:00', null, null),
      (5, '2000-01-01 00:00:00', null, null),
      (6, '2000-01-02 00:00:00', null, null),
      (7, '2000-01-02 00:00:00', null, null),
      (8, '2000-01-02 00:00:00', null, null),
      (9, '2000-01-02 00:00:00', null, null),
      (10, '2000-01-02 00:00:00', null, null),
      (11, null, null, '(50, 50)'),
      (12, null, null, '(50, 50)'),
      (13, null, null, '(50, 50)'),
      (14, null, null, '(50, 50)'),
      (15, null, null, '(50, 50)');
    """
    Ecto.Adapters.SQL.query!(Repo, insert)

    refresh = """
    REFRESH MATERIALIZED VIEW "#{meta.table_name}_view";
    """
    Ecto.Adapters.SQL.query!(Repo, refresh)

    %{conn: build_conn(), slug: meta.slug(), vpf: vpf}
  end

  test "GET /api/v2/data-sets/:slug", %{slug: slug} do
    conn = get(build_conn(), "/api/v2/data-sets/#{slug}")
    response = json_response(conn, 200)
    assert length(response["data"]) == 15
  end

  test "GET /api/v2/data-sets/:slug/@head", %{slug: slug} do
    conn = get(build_conn(), "/api/v2/data-sets/#{slug}/@head")
    response = json_response(conn, 200)
    assert is_list(response["data"])
  end

  test "GET /api/v2/data-sets/:slug/@describe", %{slug: slug} do
    conn = get(build_conn(), "/api/v2/data-sets/#{slug}/@describe")
    response = json_response(conn, 200)
    assert length(response["data"]) == 15
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
    assert response["meta"]["counts"]["total_pages"] == 2
  end

  test "GET /api/v2/data-sets/:slug pagination page and page_size parameters", %{slug: slug} do
    conn = get(build_conn(), "/api/v2/data-sets/#{slug}?page_size=5&page=2")
    response = json_response(conn, 200)
    assert length(response["data"]) == 5
    assert response["meta"]["params"]["page"] == 2
    assert response["meta"]["params"]["page_size"] == 5
  end

  test "GET /api/v2/data-sets/:slug pagination is stable with backfills", %{slug: slug} do
    conn = get(build_conn(), "/api/v2/data-sets/#{slug}?page_size=5&page=2")
    response = json_response(conn, 200)

    assert length(response["data"]) == 5
    assert response["meta"]["params"]["page"] == 2
    assert response["meta"]["params"]["page_size"] == 5
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

  test "GET /api/v2/data-sets/:slug bbox query", %{slug: slug} do
    geojson =
      """
      {
        "type": "Polygon",
        "coordinates": [
          [
            [0, 0],
            [0, 100],
            [100, 100],
            [100, 0],
            [0, 0]
          ]
        ]
      }
      """
    conn = get(build_conn(), "/api/v2/data-sets/#{slug}?bbox=#{geojson}")
    response = json_response(conn, 200)
    assert length(response["data"]) == 5
  end

  test "GET /api/v2/data-sets/:slug bbox query no results", %{slug: slug} do
    geojson =
      """
      {
        "type": "Polygon",
        "coordinates": [
          [
            [0, 0],
            [0, 1],
            [1, 1],
            [1, 0],
            [0, 0]
          ]
        ]
      }
      """
    conn = get(build_conn(), "/api/v2/data-sets/#{slug}?bbox=#{geojson}")
    response = json_response(conn, 200)
    assert length(response["data"]) == 0
  end

  test "GET /api/v2/data-sets/:slug range query", %{slug: slug} do
    conn = get(build_conn(), "/api/v2/data-sets/#{slug}?datetime=in:{\"upper\": \"3000-01-01\", \"lower\": \"2000-01-01\"}")
    response = json_response(conn, 200)
    assert length(response["data"]) == 15
  end

  test "GET /api/v2/data-sets/:slug range query no results", %{slug: slug} do
    conn = get(build_conn(), "/api/v2/data-sets/#{slug}?datetime=in:{\"upper\": \"2000-01-01 00:00:00\", \"lower\": \"3000-01-01 00:00:00\"}")
    response = json_response(conn, 200)
    assert length(response["data"]) == 0
  end

  test "GET /api/v2/data-sets/:slug location query", %{slug: slug, vpf: vpf} do
    geojson =
      """
      {
        "type": "Polygon",
        "coordinates": [
          [
            [0, 0],
            [0, 100],
            [100, 100],
            [100, 0],
            [0, 0]
          ]
        ]
      }
      """
    conn = get(build_conn(), "/api/v2/data-sets/#{slug}?#{vpf.id}=in:#{geojson}")
    response = json_response(conn, 200)
    assert length(response["data"]) == 15
  end

  test "GET /api/v2/data-sets/:slug location query no results", %{slug: slug, vpf: vpf} do
    geojson =
      """
      {
        "type": "Polygon",
        "coordinates": [
          [
            [0, 0],
            [0, 1],
            [1, 1],
            [1, 0],
            [0, 0]
          ]
        ]
      }
      """
    conn = get(build_conn(), "/api/v2/data-sets/#{slug}?#{vpf.name}=in:#{geojson}")
    response = json_response(conn, 200)
    assert length(response["data"]) == 0
  end

  test "page_size param cannot exceed 5000", %{slug: slug} do
    get(build_conn(), "/api/v2/data-sets/#{slug}?page_size=5001")
    |> json_response(422)
  end

  test "page_size param cannot be less than 1", %{slug: slug} do
    get(build_conn(), "/api/v2/data-sets/#{slug}?page_size=0")
    |> json_response(422)
  end

  test "page_size param cannot be negative", %{slug: slug} do
    get(build_conn(), "/api/v2/data-sets/#{slug}?page_size=-1")
    |> json_response(422)
  end

  test "page_size cannot be a string", %{slug: slug} do
    get(build_conn(), "/api/v2/data-sets/#{slug}?page_size=string")
    |> json_response(422)
  end

  test "valid page_size param", %{slug: slug} do
    get(build_conn(), "/api/v2/data-sets/#{slug}?page_size=501")
    |> json_response(200)
  end

  test "valid page param", %{slug: slug} do
    get(build_conn(), "/api/v2/data-sets/#{slug}?page=1")
    |> json_response(200)
  end

  test "page param can't be zero", %{slug: slug} do
    get(build_conn(), "/api/v2/data-sets/#{slug}?page=0")
    |> json_response(422)
  end

  test "page param can't be negative", %{slug: slug} do
    get(build_conn(), "/api/v2/data-sets/#{slug}?page=-1")
    |> json_response(422)
  end

  test "page param can't be a word", %{slug: slug} do
    get(build_conn(), "/api/v2/data-sets/#{slug}?page=wrong")
    |> json_response(422)
  end
end
