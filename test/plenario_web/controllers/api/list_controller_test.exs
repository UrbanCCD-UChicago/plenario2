defmodule PlenarioWeb.Api.ListControllerTest do
  use ExUnit.Case

  use Phoenix.ConnTest

  alias Plenario.ModelRegistry

  alias Plenario.Actions.{
    UserActions,
    MetaActions,
    DataSetFieldActions,
    VirtualPointFieldActions,
    DataSetActions
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
    {:ok, _} = VirtualPointFieldActions.create(meta, lat.id, lon.id)

    {:ok, meta} = MetaActions.submit_for_approval(meta)
    {:ok, meta} = MetaActions.approve(meta)
    :ok = DataSetActions.etl!(meta, @fixutre)
    {:ok, meta} = MetaActions.mark_first_import(meta)
    {:ok, meta} = MetaActions.update_latest_import(meta, NaiveDateTime.utc_now())
    bbox = MetaActions.compute_bbox!(meta)
    {:ok, meta} = MetaActions.update_bbox(meta, bbox)
    range = MetaActions.compute_time_range!(meta)
    {:ok, meta} = MetaActions.update_time_range(meta, range)

    {:ok, conn: build_conn(), user: user, meta: meta}
  end

  describe "GET /api/v2/data-sets" do
    test "it returns a 200", %{conn: conn} do
      result =
        conn
        |> get("/api/v2/data-sets")
        |> json_response(:ok)

      assert length(result["data"]) == 1
    end

    test "it only gets _ready_ data sets", %{conn: conn, user: user} do
      {:ok, _} = MetaActions.create("not ready", user, "https://example.com/not-ready", "csv")

      result =
        conn
        |> get("/api/v2/data-sets")
        |> json_response(:ok)

      assert length(result["data"]) == 1
    end
  end

  test "GET /api/v2/data-sets/@head", %{conn: conn} do
    conn = get(conn, "/api/v2/data-sets/@head")
    result = json_response(conn, 200)
    assert is_list(result["data"])
  end

  test "GET /api/v2/data-sets/@describe", %{conn: conn} do
    conn = get(conn, "/api/v2/data-sets/@describe")
    result = json_response(conn, 200)
    assert length(result["data"]) == 1
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

  test "GET /api/v2/data-sets with bbox arg", %{conn: conn, meta: meta} do
    bbox =
      meta.bbox
      |> Geo.JSON.encode()
      |> Poison.encode!()

    conn = get(conn, "/api/v2/data-sets?bbox=#{bbox}")
    result = json_response(conn, 200)
    assert length(result["data"]) == 1
  end

  test "GET /api/v2/data-sets/@describe with bbox arg", %{conn: conn, meta: meta} do
    bbox =
      meta.bbox
      |> Geo.JSON.encode()
      |> Poison.encode!()

    conn = get(conn, "/api/v2/data-sets/@describe?bbox=#{bbox}")
    result = json_response(conn, 200)
    assert length(result["data"]) == 1
  end

  test "page_size param cannot exceed 5000" do
    get(build_conn(), "/api/v2/data-sets?page_size=5001")
    |> json_response(422)
  end

  test "page_size param cannot be less than 1" do
    get(build_conn(), "/api/v2/data-sets?page_size=0")
    |> json_response(422)
  end

  test "page_size param cannot be negative" do
    get(build_conn(), "/api/v2/data-sets?page_size=-1")
    |> json_response(422)
  end

  test "page_size cannot be a string" do
    get(build_conn(), "/api/v2/data-sets?page_size=string")
    |> json_response(422)
  end

  test "valid page_size param" do
    get(build_conn(), "/api/v2/data-sets?page_size=501")
    |> json_response(200)
  end

  test "valid page param" do
    get(build_conn(), "/api/v2/data-sets?page=1")
    |> json_response(200)
  end

  test "page param can't be zero" do
    get(build_conn(), "/api/v2/data-sets?page=0")
    |> json_response(422)
  end

  test "page param can't be negative" do
    get(build_conn(), "/api/v2/data-sets?page=-1")
    |> json_response(422)
  end

  test "page param can't be a word" do
    get(build_conn(), "/api/v2/data-sets?page=wrong")
    |> json_response(422)
  end
end
