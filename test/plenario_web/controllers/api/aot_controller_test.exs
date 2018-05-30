defmodule PlenarioWeb.Api.AotControllerTest do
  use PlenarioWeb.Testing.ConnCase

  alias Plenario.Repo
  alias PlenarioAot.{AotActions, AotData, AotMeta}

  import PlenarioWeb.Api.Utils, only: [truncate: 1]

  @fixture "test/fixtures/aot-chicago.json"
  @total_records 1_365

  # Setting up the fixure data once _greatly_ reduces the test time. Drops this particular test
  # case from 40s to 11s as of writing. The downside is that in order to make this work you must
  # be explicit about database connection ownership and you must also clean up the tests yourself.
  setup_all do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, :auto)

    {:ok, meta} = AotActions.create_meta("Chicago", "https://example.com/")
    File.read!(@fixture)
    |> Poison.decode!()
    |> Enum.map(fn obj -> AotActions.insert_data(meta, obj) end)
    AotActions.compute_and_update_meta_bbox(meta)
    AotActions.compute_and_update_meta_time_range(meta)

    # Registers a callback that runs once (because we're in setup_all) after all the tests have run. Use to clean up!
    # If things screw up and this isn't called properly, `env MIX_ENV=test mix ecto.drop` (bash) is your friend.
    on_exit(fn ->
      # Check out again because this callback is run in another process.
      :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
      Ecto.Adapters.SQL.Sandbox.mode(Repo, :auto)
      truncate([AotMeta, AotData])
    end)

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
    get(build_conn(), "/api/v2/aot?page_size=5001")
    |> json_response(422)
  end

  test "page_size param cannot be less than 1" do
    get(build_conn(), "/api/v2/aot?page_size=0")
    |> json_response(422)
  end

  test "page_size param cannot be negative" do
    get(build_conn(), "/api/v2/aot?page_size=-1")
    |> json_response(422)
  end

  test "page_size cannot be a string" do
    get(build_conn(), "/api/v2/aot?page_size=string")
    |> json_response(422)
  end

  test "valid page_size param" do
    get(build_conn(), "/api/v2/aot?page_size=501")
    |> json_response(200)
  end
end
