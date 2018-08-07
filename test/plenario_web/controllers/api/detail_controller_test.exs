defmodule PlenarioWeb.Api.DetailControllerTest do
  use ExUnit.Case

  use Phoenix.ConnTest

  alias Plenario.ModelRegistry

  alias Plenario.Actions.{
    DataSetActions,
    DataSetFieldActions,
    MetaActions,
    UserActions,
    VirtualPointFieldActions
  }

  @endpoint PlenarioWeb.Endpoint

  @fixutre "test/fixtures/beach-lab-dna.csv"

  setup do
    Ecto.Adapters.SQL.Sandbox.checkout(Plenario.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Plenario.Repo, {:shared, self()})

    ModelRegistry.clear()

    {:ok, user} = UserActions.create("Test User", "test@example.com", "password")
    {:ok, meta} = MetaActions.create("Chicago Beach Lab - DNA Tests", user.id, "https://example.com/", "csv")
    {:ok, _} = DataSetFieldActions.create(meta, "DNA Test ID", "text")
    {:ok, _} = DataSetFieldActions.create(meta, "DNA Sample Timestamp", "timestamp")
    {:ok, _} = DataSetFieldActions.create(meta, "Beach", "text")
    {:ok, _} = DataSetFieldActions.create(meta, "DNA Sample 1 Reading", "float")
    {:ok, _} = DataSetFieldActions.create(meta, "DNA Sample 2 Reading", "float")
    {:ok, _} = DataSetFieldActions.create(meta, "DNA Reading Mean", "float")
    {:ok, _} = DataSetFieldActions.create(meta, "Culture Test ID", "text")
    {:ok, _} = DataSetFieldActions.create(meta, "Culture Sample 1 Timestamp", "text")
    {:ok, _} = DataSetFieldActions.create(meta, "Culture Sample 1 Reading", "text")
    {:ok, _} = DataSetFieldActions.create(meta, "Culture Sample 2 Reading", "text")
    {:ok, _} = DataSetFieldActions.create(meta, "Culture Reading Mean", "text")
    {:ok, _} = DataSetFieldActions.create(meta, "Culture Note", "text")
    {:ok, _} = DataSetFieldActions.create(meta, "Culture Sample Interval", "text")
    {:ok, _} = DataSetFieldActions.create(meta, "Culture Sample 2 Timestamp", "text")
    {:ok, lat} = DataSetFieldActions.create(meta, "Latitude", "float")
    {:ok, lon} = DataSetFieldActions.create(meta, "Longitude", "float")
    {:ok, _} = DataSetFieldActions.create(meta, "Location", "text")
    {:ok, vpf} = VirtualPointFieldActions.create(meta, lat.id, lon.id)

    {:ok, meta} = MetaActions.submit_for_approval(meta)
    {:ok, meta} = MetaActions.approve(meta)
    :ok = DataSetActions.etl!(meta, @fixutre)
    {:ok, meta} = MetaActions.mark_first_import(meta)
    {:ok, meta} = MetaActions.update_latest_import(meta, NaiveDateTime.utc_now())
    bbox = MetaActions.compute_bbox!(meta)
    {:ok, meta} = MetaActions.update_bbox(meta, bbox)
    range = MetaActions.compute_time_range!(meta)
    {:ok, meta} = MetaActions.update_time_range(meta, range)

    {:ok, conn: build_conn(), user: user, meta: meta, vpf: vpf, slug: meta.slug}
  end

  describe "GET /api/v2/data-sets/:slug" do
    test "returns a 200", %{conn: conn, slug: slug} do
      conn = get(conn, "/api/v2/data-sets/#{slug}")
      response = json_response(conn, 200)
      assert length(response["data"]) == 500
    end

    test "404s for a non-ready data set", %{conn: conn, user: user} do
      {:ok, meta} = MetaActions.create("not ready", user, "https://example.com/not-ready", "csv")

      conn
      |> get("/api/v2/data-sets/#{meta.slug}")
      |> json_response(:not_found)
    end
  end

  test "GET /api/v2/data-sets/does_not_exist" do
    conn = get(build_conn(), "/api/v2/data-sets/does_not_exist")
    assert json_response(conn, 404)
  end

  test "GET /api/v2/data-sets/:slug/@head", %{slug: slug} do
    conn = get(build_conn(), "/api/v2/data-sets/#{slug}/@head")
    response = json_response(conn, 200)
    assert is_list(response["data"])
  end

  test "GET /api/v2/data-sets/:slug/@describe", %{slug: slug} do
    conn = get(build_conn(), "/api/v2/data-sets/#{slug}/@describe")
    response = json_response(conn, 200)
    assert length(response["data"]) == 500
  end

  test "GET /api/v2/data-sets/:slug pagination page parameter", %{slug: slug} do
    conn = get(build_conn(), "/api/v2/data-sets/#{slug}?page=2")
    response = json_response(conn, 200)
    assert length(response["data"]) == 500
    assert response["meta"]["counts"]["total_pages"] == 6
  end

  test "GET /api/v2/data-sets/:slug pagination page_size parameter", %{slug: slug} do
    conn = get(build_conn(), "/api/v2/data-sets/#{slug}?page_size=10")
    response = json_response(conn, 200)
    assert length(response["data"]) == 10
    assert response["meta"]["counts"]["total_pages"] == 294
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
    assert response["meta"]["links"]["previous"] =~ "page_size=5&page=1"
    assert response["meta"]["links"]["next"] =~ "page_size=5&page=3"
  end

  test "GET /api/v2/data-sets/:slug has stable pagination", %{slug: slug} do
    res =
      conn
      |> get("/api/v2/data-sets/#{slug}?page_size=5")
      |> json_response(:ok)

    Enum.with_index(res["data"])
    |> Enum.each(fn {row, idx} ->
      assert row["row_id"] < Enum.at(res["data"], idx+1)["row_id"]
    end)

    last = List.last(res["data"])

    res =
      conn
      |> get("/api/v2/data-sets/#{slug}?page_size=5&page=2")
      |> json_response(:ok)

    Enum.with_index(res["data"])
    |> Enum.each(fn {row, idx} ->
      assert row["row_id"] < Enum.at(res["data"], idx+1)["row_id"]
    end)

    first = List.first(res["data"])

    assert last["row_id"] < first["row_id"]
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
            [100, 100],
            [100, -100],
            [-100, -100],
            [-100, 100],
            [100, 100]
          ]
        ]
      }
      """
    conn = get(build_conn(), "/api/v2/data-sets/#{slug}?bbox=#{geojson}")
    response = json_response(conn, 200)
    assert length(response["data"]) == 500
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
    conn = get(build_conn(), "/api/v2/data-sets/#{slug}?DNA+Sample+Timestamp=in:{\"upper\": \"3000-01-01\", \"lower\": \"2000-01-01\"}")
    response = json_response(conn, 200)
    assert length(response["data"]) == 500
  end

  test "GET /api/v2/data-sets/:slug range query no results", %{slug: slug} do
    conn = get(build_conn(), "/api/v2/data-sets/#{slug}?DNA+Sample+Timestamp=in:{\"upper\": \"1985-01-01 00:00:00\", \"lower\": \"1986-01-01 00:00:00\"}")
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
    assert length(response["data"]) == 500
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
