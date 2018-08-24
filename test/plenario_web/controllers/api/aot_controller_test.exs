defmodule PlenarioWeb.Api.AotControllerTest do
  use ExUnit.Case

  use Phoenix.ConnTest

  import PlenarioWeb.Router.Helpers

  alias PlenarioAot.AotActions

  @endpoint PlenarioWeb.Endpoint

  @fixture "test/fixtures/aot-chicago.json"

  setup_all do
    Ecto.Adapters.SQL.Sandbox.checkout(Plenario.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Plenario.Repo, {:shared, self()})

    {:ok, meta} = AotActions.create_meta("Chicago", "https://example.com/chicago")

    Plenario.Repo.transaction(fn ->
      File.read!(@fixture)
      |> Poison.decode!()
      |> Enum.map(&AotActions.insert_data(meta, &1))
    end)

    AotActions.compute_and_update_meta_bbox(meta)
    AotActions.compute_and_update_meta_time_range(meta)

    {:ok, conn: build_conn(), meta: meta}
  end

  describe "GET /aot" do
    test "applies page number", %{conn: conn} do
      res =
        conn
        |> get(aot_path(conn, :get))
        |> json_response(:ok)

      assert res["meta"]["params"]["page"] == 1
    end

    test "applies page size", %{conn: conn} do
      res =
        conn
        |> get(aot_path(conn, :get))
        |> json_response(:ok)

      assert res["meta"]["params"]["page_size"] == 200
    end

    test "applies order", %{conn: conn} do
      res =
        conn
        |> get(aot_path(conn, :get))
        |> json_response(:ok)

      assert res["meta"]["params"]["order_by"] == %{"desc" => "timestamp"}
    end

    test "applies window", %{conn: conn} do
      res =
        conn
        |> get(aot_path(conn, :get))
        |> json_response(:ok)

      refute res["meta"]["params"]["window"] == nil
    end

    test "when given format=geojson it will respond with data objects formatted as geojson", %{
      conn: conn
    } do
      res =
        conn
        |> get(aot_path(conn, :get, %{format: "geojson"}))
        |> json_response(:ok)

      res["data"]
      |> Enum.each(fn record -> assert Map.keys(record) == ["geometry", "properties", "type"] end)
    end
  end

  describe "GET /aot with filters" do
    test "with a good bbox will be :ok", %{conn: conn} do
      bbox =
        %Geo.Polygon{
          srid: 4326,
          coordinates: [
            [
              {1, 2},
              {1, 1},
              {2, 1},
              {2, 2},
              {1, 2}
            ]
          ]
        }
        |> Geo.JSON.encode()
        |> Poison.encode!()

      conn
      |> get(aot_path(conn, :get, %{location: "within:#{bbox}"}))
      |> json_response(:ok)
    end

    test "with a malformed bbox will be :bad_request", %{conn: conn} do
      conn
      |> get(aot_path(conn, :get, %{location: "within:chicago"}))
      |> json_response(:bad_request)
    end

    test "with a good timerange will be :ok", %{conn: conn} do
      range =
        %Plenario.TsRange{
          lower: ~N[2018-01-01 00:00:00],
          upper: ~N[2019-01-01 00:00:00],
          upper_inclusive: false
        }
        |> Poison.encode!()

      conn
      |> get(aot_path(conn, :get, %{timestamp: "within:#{range}"}))
      |> json_response(:ok)
    end

    test "with a malformed timerange will be :bad_request", %{conn: conn} do
      conn
      |> get(aot_path(conn, :get, %{timestamp: "within:last week"}))
      |> json_response(:bad_request)
    end

    test "with an unknown network name will be :ok and yield 0 results", %{conn: conn} do
      # flaky test; let it sleep
      Process.sleep(500)

      res =
        conn
        |> get(aot_path(conn, :get, %{network_name: "the-moon"}))
        |> json_response(:ok)

      assert length(res["data"]) == 0

      assert res["meta"]["counts"] == %{
               "data_count" => 0,
               "total_pages" => 1,
               "total_records" => 0
             }
    end

    test "with an array of node ids will be :ok", %{conn: conn} do
      # flaky test; let it sleep
      Process.sleep(500)

      res =
        conn
        |> get(aot_path(conn, :get, %{node_id: ["080", "081"]}))
        |> json_response(:ok)

      assert length(res["data"]) == 9
    end
  end

  describe "GET /aot/@head" do
    setup do
      # All of these tests can be flaky.
      Process.sleep(500)
    end

    test "in default order", %{conn: conn} do
      res =
        conn
        |> get(aot_path(conn, :head))
        |> json_response(:ok)

      head =
        res["data"]
        |> List.first()

      assert head["timestamp"] == "2018-03-07T15:54:04.000000"
    end

    test "in custom order", %{conn: conn} do
      res =
        conn
        |> get(aot_path(conn, :head, %{order_by: "asc:timestamp"}))
        |> json_response(:ok)

      head =
        res["data"]
        |> List.first()

      assert head["timestamp"] == "2018-03-07T15:54:04.000000"
    end

    test "when given format=geojson it will respond with data objects formatted as geojson", %{
      conn: conn
    } do
      res =
        conn
        |> get(aot_path(conn, :head, %{format: "geojson"}))
        |> json_response(:ok)

      res["data"]
      |> Enum.each(fn record -> assert Map.keys(record) == ["geometry", "properties", "type"] end)
    end
  end

  describe "GET /aot/@describe" do
    test "with a single network", %{conn: conn} do
      res =
        conn
        |> get(aot_path(conn, :describe))
        |> json_response(:ok)

      assert length(res["data"]) == 1
    end

    test "with multiple networks", %{conn: conn} do
      {:ok, meta} = AotActions.create_meta("Detroit", "https://example.com/detroit")

      res =
        conn
        |> get(aot_path(conn, :describe))
        |> json_response(:ok)

      assert length(res["data"]) == 2

      # clean this up
      Plenario.Repo.delete!(meta)
    end

    test "when given format=geojson it will respond with data objects formatted as geojson", %{
      conn: conn
    } do
      res =
        conn
        |> get(aot_path(conn, :describe, %{format: "geojson"}))
        |> json_response(:ok)

      res["data"]
      |> Enum.each(fn record -> assert Map.keys(record) == ["geometry", "properties", "type"] end)
    end
  end
end
