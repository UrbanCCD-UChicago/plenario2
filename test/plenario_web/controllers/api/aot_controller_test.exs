defmodule PlenarioWeb.Api.AotControllerTest do
  use PlenarioWeb.Testing.ConnCase

  alias PlenarioAot.AotActions

  @fixture "test/fixtures/aot-chicago.json"
  @total_records 1_365

  setup do
    {:ok, meta} = AotActions.create_meta("Chicago", "https://example.com/")
    File.read!(@fixture)
    |> Poison.decode!()
    |> Enum.map(fn obj -> AotActions.insert_data(meta, obj) end)
    AotActions.compute_and_update_meta_bbox(meta)
    AotActions.compute_and_update_meta_time_range(meta)

    {:ok, [meta: meta]}
  end

  test "GET /api/v2/aot", %{conn: conn} do
    conn = get(conn, "/api/v2/aot")
    %{"meta" => meta, "data" => data} = json_response(conn, 200)

    assert is_map(meta)
    assert Map.has_key?(meta, "links")
    links = meta["links"]
    assert is_map(links)
    assert Map.has_key?(links, "current")
    assert Map.has_key?(links, "previous")
    assert Map.has_key?(links, "next")
    assert Map.has_key?(meta, "params")
    params = meta["params"]
    assert is_map(params)
    assert Map.has_key?(meta, "counts")
    counts = meta["counts"]
    assert Map.has_key?(counts, "data")
    assert Map.has_key?(counts, "errors")
    assert Map.has_key?(counts, "total_pages")
    assert Map.has_key?(counts, "total_records")
    assert counts["total_records"] == @total_records

    assert is_list(data)
    assert length(data) == 500
    first = Enum.at(data, 0)
    assert is_map(first)
    assert Map.has_key?(first, "node_id")
    assert Map.has_key?(first, "human_address")
    assert Map.has_key?(first, "timestamp")
    assert Map.has_key?(first, "latitude")
    assert Map.has_key?(first, "longitude")
    assert Map.has_key?(first, "observations")
  end

  test "GET /api/v2/aot/@head", %{conn: conn} do
    conn = get(conn, "/api/v2/aot/@head")
    %{"meta" => meta, "data" => data} = json_response(conn, 200)

    assert is_map(meta)
    assert Map.has_key?(meta, "links")
    links = meta["links"]
    assert is_map(links)
    assert Map.has_key?(links, "current")
    assert Map.has_key?(links, "previous")
    assert Map.has_key?(links, "next")
    assert Map.has_key?(meta, "params")
    params = meta["params"]
    assert is_map(params)
    assert Map.has_key?(meta, "counts")
    counts = meta["counts"]
    assert Map.has_key?(counts, "data")
    assert Map.has_key?(counts, "errors")
    assert Map.has_key?(counts, "total_pages")
    assert Map.has_key?(counts, "total_records")

    assert is_list(data)
    assert length(data) == 1
    first = Enum.at(data, 0)
    assert is_map(first)
    assert Map.has_key?(first, "node_id")
    assert Map.has_key?(first, "human_address")
    assert Map.has_key?(first, "timestamp")
    assert Map.has_key?(first, "latitude")
    assert Map.has_key?(first, "longitude")
    assert Map.has_key?(first, "observations")
  end

  test "GET /api/v2/aot/@describe", %{conn: conn} do
    conn = get(conn, "/api/v2/aot/@describe")
    %{"meta" => meta, "data" => data} = json_response(conn, 200)

    assert is_map(meta)
    assert Map.has_key?(meta, "links")
    links = meta["links"]
    assert is_map(links)
    assert Map.has_key?(links, "current")
    assert Map.has_key?(links, "previous")
    assert Map.has_key?(links, "next")
    assert Map.has_key?(meta, "params")
    params = meta["params"]
    assert is_map(params)
    assert Map.has_key?(meta, "counts")
    counts = meta["counts"]
    assert Map.has_key?(counts, "data")
    assert Map.has_key?(counts, "errors")
    assert Map.has_key?(counts, "total_pages")
    assert Map.has_key?(counts, "total_records")

    assert is_list(data)
    assert length(data) == 1
    first = Enum.at(data, 0)
    assert is_map(first)
    assert Map.has_key?(first, "network_name")
    assert Map.has_key?(first, "slug")
    assert Map.has_key?(first, "source_url")
    assert Map.has_key?(first, "bbox")
    assert Map.has_key?(first, "time_range")
  end

  describe "GET with filter" do
    test "network_name", %{conn: conn} do
      conn = get(conn, "/api/v2/aot?network_name=chicago")
      %{"meta" => meta, "data" => _} = json_response(conn, 200)
      assert meta["counts"]["total_records"] == @total_records

      conn = get(conn, "/api/v2/aot?network_name=outer-space")
      %{"meta" => meta, "data" => _} = json_response(conn, 200)
      assert meta["counts"]["total_records"] == 0

      conn = get(conn, "/api/v2/aot?network_name=outer-space&network_name=chicago")
      %{"meta" => meta, "data" => _} = json_response(conn, 200)
      assert meta["counts"]["total_records"] == @total_records
    end

    test "bbox", %{conn: conn} do
      min_lat = 41.95
      max_lat = 41.97
      min_lon = -87.65
      max_lon = -87.67
      bbox = %Geo.Polygon{
        srid: 4326,
        coordinates: [[
          {min_lat, max_lon},
          {min_lat, min_lon},
          {max_lat, min_lon},
          {max_lat, max_lon},
          {min_lat, max_lon}
        ]]
      } |> Geo.JSON.encode()
      conn = get(conn, "/api/v2/aot?bbox=#{bbox}")
      %{"meta" => meta, "data" => _} = json_response(conn, 200)
      assert meta["counts"]["total_records"] == @total_records
    end

    test "timestamp", %{conn: conn} do
      conn = get(conn, "/api/v2/aot?timestamp=2018-01-01T00:00:00Z")
      %{"meta" => meta, "data" => _} = json_response(conn, 200)
      assert meta["counts"]["total_records"] == 0

      conn = get(conn, "/api/v2/aot?timestamp=eq:2018-01-01T00:00:00Z")
      %{"meta" => meta, "data" => _} = json_response(conn, 200)
      assert meta["counts"]["total_records"] == 0

      conn = get(conn, "/api/v2/aot?timestamp=gt:2018-01-01T00:00:00Z")
      %{"meta" => meta, "data" => _} = json_response(conn, 200)
      assert meta["counts"]["total_records"] == @total_records

      conn = get(conn, "/api/v2/aot?timestamp=ge:2018-01-01T00:00:00Z")
      %{"meta" => meta, "data" => _} = json_response(conn, 200)
      assert meta["counts"]["total_records"] == @total_records

      conn = get(conn, "/api/v2/aot?timestamp=lt:2018-01-01T00:00:00Z")
      %{"meta" => meta, "data" => _} = json_response(conn, 200)
      assert meta["counts"]["total_records"] == 0

      conn = get(conn, "/api/v2/aot?timestamp=le:2018-01-01T00:00:00Z")
      %{"meta" => meta, "data" => _} = json_response(conn, 200)
      assert meta["counts"]["total_records"] == 0

      conn = get(conn, "/api/v2/aot?timestamp=in:{\"lower\":\"2018-01-01T00:00:00Z\",\"upper\":\"2019-01-01T00:00:00Z\"}")
      %{"meta" => meta, "data" => _} = json_response(conn, 200)
      assert meta["counts"]["total_records"] == @total_records
    end

    test "node_id", %{conn: conn} do
      conn = get(conn, "/api/v2/aot?node_id=088")
      %{"meta" => meta, "data" => _} = json_response(conn, 200)
      assert meta["counts"]["total_records"] == 70

      conn = get(conn, "/api/v2/aot?node_id=000")
      %{"meta" => meta, "data" => _} = json_response(conn, 200)
      assert meta["counts"]["total_records"] == 0

      conn = get(conn, "/api/v2/aot?node_id=000&node_id=088")
      %{"meta" => meta, "data" => _} = json_response(conn, 200)
      assert meta["counts"]["total_records"] == 70
    end

    test "sensor", %{conn: conn} do
      conn = get(conn, "/api/v2/aot?sensor=BMP180")
      %{"meta" => meta, "data" => _} = json_response(conn, 200)
      assert meta["counts"]["total_records"] == @total_records

      conn = get(conn, "/api/v2/aot?sensor=eyes")
      %{"meta" => meta, "data" => _} = json_response(conn, 200)
      assert meta["counts"]["total_records"] == 0

      conn = get(conn, "/api/v2/aot?sensor=eyes&sensor=BMP180")
      %{"meta" => meta, "data" => _} = json_response(conn, 200)
      assert meta["counts"]["total_records"] == @total_records
    end

    test "network_name and node_id", %{conn: conn} do
      conn = get(conn, "/api/v2/aot?network_name=chicago&node_id=088")
      %{"meta" => meta, "data" => _} = json_response(conn, 200)
      assert meta["counts"]["total_records"] == 70
    end

    # TODO: write test after implementation
    # test "observations" do
    # end
  end

  test "page_size param cannot exceed 5000" do
    %{"meta" => meta, "errors" => errors} =
      get(build_conn(), "/api/v2/aot?page_size=5001")
      |> json_response(422)

    assert meta["counts"]["total_records"] == 0
    assert errors == [[page_size: "Argument cannot exceed 5000."]]
  end

  test "page_size param cannot be less than 1" do
    %{"meta" => meta, "errors" => errors} =
      get(build_conn(), "/api/v2/aot?page_size=0")
      |> json_response(422)

    assert meta["counts"]["total_records"] == 0
    assert errors == [[page_size: "Argument cannot be less than 1."]]
  end

  test "page_size param cannot be negative" do
    %{"meta" => meta, "errors" => errors} =
      get(build_conn(), "/api/v2/aot?page_size=-1")
      |> json_response(422)

    assert meta["counts"]["total_records"] == 0
    assert errors == [[page_size: "Argument cannot be less than 1."]]
  end
end
