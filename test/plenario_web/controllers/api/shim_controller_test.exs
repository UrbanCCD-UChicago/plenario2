defmodule PlenarioWeb.Api.ShimControllerTest do
  use ExUnit.Case
  use Phoenix.ConnTest

  alias Plenario.{
    ModelRegistry,
    Repo
  }

  alias Plenario.Actions.{
    DataSetActions,
    DataSetFieldActions,
    MetaActions,
    UserActions,
    VirtualPointFieldActions
  }

  alias PlenarioAot.AotActions

  @aot_fixture_path "test/fixtures/aot-chicago-future.json"
  @endpoint PlenarioWeb.Endpoint

  setup do
    Ecto.Adapters.SQL.Sandbox.checkout(Plenario.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Plenario.Repo, {:shared, self()})

    {:ok, user} = UserActions.create("API Test User", "test@example.com", "password")
    {:ok, meta} = MetaActions.create("API Test Dataset", user.id, "https://www.example.com", "csv")
    {:ok, _} = DataSetFieldActions.create(meta.id, "pk", "integer")
    {:ok, _} = DataSetFieldActions.create(meta.id, "datetime", "timestamp")
    {:ok, location} = DataSetFieldActions.create(meta.id, "location", "text")
    {:ok, _} = DataSetFieldActions.create(meta.id, "data", "text")
    {:ok, vpf} = VirtualPointFieldActions.create(meta, location.id)

    MetaActions.update_latest_import(meta, NaiveDateTime.utc_now())

    DataSetActions.up!(meta)
    ModelRegistry.clear()

    insert = """
    INSERT INTO "#{meta.table_name}"
      (pk, datetime, data, location)
    VALUES
      (1, '2500-01-01 00:00:00', null, '(0, 0)'),
      (2, '2500-01-01 00:00:00', null, '(0, 0)'),
      (3, '2500-01-01 00:00:00', null, '(0, 0)'),
      (4, '2500-01-01 00:00:00', null, '(0, 0)'),
      (5, '2500-01-01 00:00:00', null, '(0, 0)'),
      (6, '2500-01-02 00:00:00', null, '(50, 50)'),
      (7, '2500-01-02 00:00:00', null, '(50, 50)'),
      (8, '2500-01-02 00:00:00', null, '(50, 50)'),
      (9, '2500-01-02 00:00:00', null, '(50, 50)'),
      (10, '2500-01-02 00:00:00', null, '(50, 50)'),
      (11, '2500-01-02 00:00:00', null, '(100, 50)'),
      (12, '2500-01-02 00:00:00', null, '(100, 50)'),
      (13, '2500-01-02 00:00:00', null, '(100, 50)'),
      (14, '2500-01-02 00:00:00', null, '(100, 50)'),
      (15, '2500-01-03 00:00:00', null, '(100, 50)');
    """
    Ecto.Adapters.SQL.query!(Repo, insert)

    refresh = """
    REFRESH MATERIALIZED VIEW "#{meta.table_name}_view";
    """
    Ecto.Adapters.SQL.query!(Repo, refresh)

    imetas = Enum.map((1..5), fn i ->
      {:ok, m} = MetaActions.create("META #{i}", user.id, "https://www.example.com/#{i}", "csv")
      {:ok, _} = DataSetFieldActions.create(m, "dummy", "integer")
      DataSetActions.up!(m)
      MetaActions.update_latest_import(m, NaiveDateTime.from_iso8601!("2000-01-0#{i}T00:00:00"))
      m
    end)

    metas = imetas ++ [meta]
    Enum.each(metas, fn meta ->
      refresh = """
      REFRESH MATERIALIZED VIEW "#{meta.table_name}_view";
      """
      {:ok, _} = Repo.query(refresh)
    end)

    {:ok, aot_meta} = AotActions.create_meta("Chicago", "https://example.com/")

    File.read!(@aot_fixture_path)
    |> Poison.decode!()
    |> Enum.map(fn obj -> AotActions.insert_data(aot_meta, obj) end)

    AotActions.compute_and_update_meta_bbox(aot_meta)
    AotActions.compute_and_update_meta_time_range(aot_meta)

    %{
      meta: meta,
      vpf: vpf,
      conn: build_conn()
    }
  end

  test "GET /api/v1/datasets", %{conn: conn} do
    get(conn, "/api/v1/datasets")
    |> json_response(200)
  end

  test "GET /api/v1/detail", %{conn: conn, meta: meta} do
    get(conn, "/api/v1/detail?dataset_name=#{meta.slug}")
    |> json_response(200)
  end

  test "GET /api/v1/detail has no 'dataset_name'", %{conn: conn} do
    get(conn, "/api/v1/detail")
    |> json_response(422)
  end

  test "GET /api/v1/detail __ gt", %{conn: conn, meta: meta} do
    get(conn, "/api/v1/detail?dataset_name=#{meta.slug}")
    |> json_response(200)
  end

  test "GET /v1/api/detail", %{conn: conn, meta: meta} do
    get(conn, "/v1/api/detail?dataset_name=#{meta.slug}")
    |> json_response(200)
  end

  test "GET /v1/api/detail has no 'dataset_name'", %{conn: conn} do
    get(conn, "/v1/api/detail")
    |> json_response(422)
  end

  test "GET /v1/api/detail __ ge", %{conn: conn, meta: meta} do
    result =
      get(conn, "/v1/api/detail?dataset_name=#{meta.slug}&datetime__ge=2500-01-01T00:00:00")
      |> json_response(200)

    assert length(result["objects"]) == 15

    result =
      get(conn, "/v1/api/detail?dataset_name=#{meta.slug}&datetime__ge=2500-01-02T00:00:00")
      |> json_response(200)

    assert length(result["objects"]) == 10
  end

  test "GET /v1/api/detail __gt", %{conn: conn, meta: meta} do
    result =
      get(conn, "/v1/api/detail?dataset_name=#{meta.slug}&datetime__gt=2500-01-01T00:00:00")
      |> json_response(200)

    assert length(result["objects"]) == 10

    result =
      get(conn, "/v1/api/detail?dataset_name=#{meta.slug}&datetime__gt=2500-01-02T00:00:00")
      |> json_response(200)

    assert result["meta"]["total"] == 1
  end

  test "GET /v1/api/detail __lt", %{conn: conn, meta: meta} do
    result =
      get(conn, "/v1/api/detail?dataset_name=#{meta.slug}&datetime__lt=2500-01-01T00:00:00")
      |> json_response(200)

    assert length(result["objects"]) == 0

    result =
      get(conn, "/v1/api/detail?dataset_name=#{meta.slug}&datetime__lt=2500-01-02T00:00:00")
      |> json_response(200)

    assert length(result["objects"]) == 5
  end

  test "GET /v1/api/detail __le", %{conn: conn, meta: meta} do
    result =
      get(conn, "/v1/api/detail?dataset_name=#{meta.slug}&datetime__le=2500-01-01T00:00:00")
      |> json_response(200)

    assert length(result["objects"]) == 5

    result =
      get(conn, "/v1/api/detail?dataset_name=#{meta.slug}&datetime__le=2500-01-02T00:00:00")
      |> json_response(200)

    assert length(result["objects"]) == 14
  end

  test "GET /api/v1/detail __eq", %{conn: conn, meta: meta} do
    result =
      get(conn, "/v1/api/detail?dataset_name=#{meta.slug}&datetime__eq=2500-01-02T00:00:00")
      |> json_response(200)

    assert length(result["objects"]) == 9
  end

  test "GET /v1/api/datasets", %{conn: conn} do
    result = json_response(get(conn, "/api/v1/datasets"), 200)
    assert length(result["objects"]) == 6
  end

  test "GET /api/v1/datasets has correct count", %{conn: conn} do
    result = json_response(get(conn, "/api/v1/datasets"), 200)
    assert result["meta"]["total"] == 6
  end

  test "GET /v1/api/datasets __ge", %{conn: conn} do
    result = json_response(get(conn, "/api/v1/datasets?latest_import__ge=2000-01-03T00:00:00"), 200)
    assert result["meta"]["total"] == 4
  end

  test "GET /v1/api/datasets __gt", %{conn: conn} do
    result = json_response(get(conn, "/api/v1/datasets?latest_import__gt=2000-01-03T00:00:00"), 200)
    assert result["meta"]["total"] == 3
  end

  test "GET /v1/api/datasets __le", %{conn: conn} do
    result = json_response(get(conn, "/api/v1/datasets?latest_import__le=2000-01-03T00:00:00"), 200)
    assert result["meta"]["total"] == 3
  end

  test "GET /v1/api/datasets __lt", %{conn: conn} do
    result = json_response(get(conn, "/api/v1/datasets?latest_import__lt=2000-01-03T00:00:00"), 200)
    assert result["meta"]["total"] == 2
  end

  test "GET /v1/api/datasets __eq", %{conn: conn} do
    result = json_response(get(conn, "/api/v1/datasets?latest_import__eq=2000-01-03T00:00:00"), 200)
    assert result["meta"]["total"] == 1
  end

  test "GET /v1/api/detail obs_date", %{conn: conn, meta: meta} do
    result =
      conn
      |> get("/api/v1/detail"
        <> "?dataset_name=#{meta.slug}"
        <> "&obs_date__le=2500-01-01T00:00:00")
      |> json_response(200)

    assert result["meta"]["total"] == 5
    assert length(result["objects"]) == 5
  end

  test "GET /v1/api/detail location_geom__within", %{conn: conn, meta: meta} do
    geom =
      """
      {
        "type":"Polygon",
        "coordinates":[
           [
              [0.0, 0.0],
              [0.0, 125.0],
              [125.0, 125.0],
              [125.0, 0.0],
              [0.0, 0.0]
           ]
        ]
      }
      """

    result =
      conn
      |> get("/api/v1/detail"
        <> "?dataset_name=#{meta.slug}"
        <> "&location_geom__within=#{geom}")
      |> json_response(200)

    assert result["meta"]["total"] == 10
    assert length(result["objects"]) == 10
  end

  test "GET /v1/api/detail obs_date & geom", %{conn: conn, meta: meta} do
    geom =
      """
      {
        "type":"Polygon",
        "coordinates":[
           [
              [0.0, 0.0],
              [0.0, 125.0],
              [125.0, 125.0],
              [125.0, 0.0],
              [0.0, 0.0]
           ]
        ]
      }
      """

    result =
      conn
      |> get("/api/v1/detail"
        <> "?dataset_name=#{meta.slug}"
        <> "&location_geom__within=#{geom}"
        <> "&obs_date__ge=2500-01-03T00:00:00")
      |> json_response(200)

    assert result["meta"]["total"] == 1
  end

  test "V1 format special columns for metas at /datasets endpoint", %{vpf: vpf} do
    result =
      build_conn()
      |> get("/api/v1/datasets")
      |> json_response(200)

    meta = Enum.find(result["objects"], fn
      m -> m["dataset_name"] == "api-test-dataset"
    end)

    assert meta["observed_date"] == "datetime"
    assert meta["location"] == vpf.name
  end

  test "V1 keyword offset behaves like page for datasets" do
    result =
      build_conn()
      |> get("/api/v1/datasets?limit=1&offset=2")
      |> json_response(200)

    [first_meta | _ ] = result["objects"]

    assert first_meta["human_name"] == "META 2"
  end

  test "V1 keyword limit behaves like page_size for datasets" do
    result =
      build_conn()
      |> get("/api/v1/datasets?limit=2")
      |> json_response(200)

    assert length(result["objects"]) == 2
  end

  test "V1 keyword offset behaves like page for detail", %{meta: meta} do
    result =
      build_conn()
      |> get("/api/v1/detail?dataset_name=#{meta.slug}&offset=4&limit=1")
      |> json_response(200)

    [first_record | _ ] = result["objects"]

    assert first_record["pk"] == 5
  end

  test "V1 keyword limit behaves like page_size for detail", %{meta: meta} do
    result =
      build_conn()
      |> get("/api/v1/detail?dataset_name=#{meta.slug}&limit=2")
      |> json_response(200)

    assert length(result["objects"]) == 2
  end
end
