defmodule PlenarioWeb.Testing.DataSetApiControllerTest do
  use PlenarioWeb.Testing.ConnCase

  import Plenario.Testing.DataCase

  alias Plenario.{
    DataSetActions,
    Repo
  }

  setup do
    user = create_user()

    crimes = create_data_set(%{user: user}, name: "crimes", src_url: "https://example.com/1")
    create_field(%{data_set: crimes}, [name: ":id", type: "text"])
    create_field(%{data_set: crimes}, [name: "ID", type: "text"])
    create_field(%{data_set: crimes}, [name: "Case Number", type: "text"])
    create_field(%{data_set: crimes}, [name: "Date", type: "timestamp"])
    create_field(%{data_set: crimes}, [name: "Block", type: "text"])
    create_field(%{data_set: crimes}, [name: "IUCR", type: "text"])
    create_field(%{data_set: crimes}, [name: "Primary Type", type: "text"])
    create_field(%{data_set: crimes}, [name: "Description", type: "text"])
    create_field(%{data_set: crimes}, [name: "Location Description", type: "text"])
    create_field(%{data_set: crimes}, [name: "Arrest", type: "boolean"])
    create_field(%{data_set: crimes}, [name: "Domestic", type: "boolean"])
    create_field(%{data_set: crimes}, [name: "Beat", type: "text"])
    create_field(%{data_set: crimes}, [name: "District", type: "text"])
    create_field(%{data_set: crimes}, [name: "Ward", type: "text"])
    create_field(%{data_set: crimes}, [name: "Community Area", type: "text"])
    create_field(%{data_set: crimes}, [name: "FBI Code", type: "text"])
    create_field(%{data_set: crimes}, [name: "X Coordinate", type: "integer"])
    create_field(%{data_set: crimes}, [name: "Y Coordinate", type: "integer"])
    create_field(%{data_set: crimes}, [name: "Year", type: "integer"])
    create_field(%{data_set: crimes}, [name: "Updated On", type: "timestamp"])
    create_field(%{data_set: crimes}, [name: "Latitude", type: "float"])
    create_field(%{data_set: crimes}, [name: "Longitude", type: "float"])
    loc = create_field(%{data_set: crimes}, [name: "Location", type: "text"])
    create_virtual_point(%{data_set: crimes, field: loc})

    {:ok, crimes} = DataSetActions.update(crimes, state: "ready")
    :ok = Repo.up!(crimes)
    :ok = Repo.etl!(crimes, "test/fixtures/crimes.csv")
    bbox = DataSetActions.compute_bbox!(crimes)
    hull = DataSetActions.compute_hull!(crimes)
    time_range = DataSetActions.compute_time_range!(crimes)
    {:ok, crimes} = DataSetActions.update(crimes, bbox: bbox, hull: hull, time_range: time_range)

    potholes = create_data_set(%{user: user}, name: "potholes", src_url: "https://example.com/2")
    create_field(%{data_set: potholes}, [name: ":id", type: "text"])
    create_field(%{data_set: potholes}, [name: "CREATION DATE", type: "timestamp"])
    create_field(%{data_set: potholes}, [name: "STATUS", type: "text"])
    create_field(%{data_set: potholes}, [name: "COMPLETION DATE", type: "timestamp"])
    create_field(%{data_set: potholes}, [name: "SERVICE REQUEST NUMBER", type: "text"])
    create_field(%{data_set: potholes}, [name: "TYPE OF SERVICE REQUEST", type: "text"])
    create_field(%{data_set: potholes}, [name: "CURRENT ACTIVITY", type: "text"])
    create_field(%{data_set: potholes}, [name: "MOST RECENT ACTION", type: "text"])
    create_field(%{data_set: potholes}, [name: "NUMBER OF POTHOLES FILLED ON BLOCK", type: "text"])
    create_field(%{data_set: potholes}, [name: "STREET ADDRESS", type: "text"])
    create_field(%{data_set: potholes}, [name: "ZIP", type: "text"])
    create_field(%{data_set: potholes}, [name: "X COORDINATE", type: "text"])
    create_field(%{data_set: potholes}, [name: "Y COORDINATE", type: "text"])
    create_field(%{data_set: potholes}, [name: "Ward", type: "text"])
    create_field(%{data_set: potholes}, [name: "Police District", type: "text"])
    create_field(%{data_set: potholes}, [name: "Community Area", type: "text"])
    create_field(%{data_set: potholes}, [name: "LATITUDE", type: "text"])
    create_field(%{data_set: potholes}, [name: "LONGITUDE", type: "text"])
    loc = create_field(%{data_set: potholes}, [name: "LOCATION", type: "text"])
    create_virtual_point(%{data_set: potholes, field: loc})

    {:ok, potholes} = DataSetActions.update(potholes, state: "ready")
    :ok = Repo.up!(potholes)
    :ok = Repo.etl!(potholes, "test/fixtures/potholes.csv")
    bbox = DataSetActions.compute_bbox!(potholes)
    hull = DataSetActions.compute_hull!(potholes)
    time_range = DataSetActions.compute_time_range!(potholes)
    {:ok, potholes} = DataSetActions.update(potholes, bbox: bbox, hull: hull, time_range: time_range)

    {:ok, [crimes: crimes, potholes: potholes]}
  end

  describe "list" do
    test "should apply default order", %{conn: conn} do
      resp =
        conn
        |> get(Routes.data_set_api_path(conn, :list))
        |> json_response(:ok)

      assert resp["meta"]["query"]["order"] == ["asc", "name"]
    end

    test "should apply default pagination", %{conn: conn} do
      resp =
        conn
        |> get(Routes.data_set_api_path(conn, :list))
        |> json_response(:ok)

      assert resp["meta"]["query"]["paginate"] == [1, 200]
    end

    test "applies with_user param", %{conn: conn} do
      resp =
        conn
        |> get(Routes.data_set_api_path(conn, :list, with_user: true))
        |> json_response(:ok)

      resp["data"]
      |> Enum.each(& assert is_map &1["user"])
    end

    test "applies with_fields param", %{conn: conn} do
      resp =
        conn
        |> get(Routes.data_set_api_path(conn, :list, with_fields: true))
        |> json_response(:ok)

      resp["data"]
      |> Enum.each(& assert is_list &1["fields"])
    end

    test "applies with_virtual_dates param", %{conn: conn} do
      resp =
        conn
        |> get(Routes.data_set_api_path(conn, :list, with_virtual_dates: true))
        |> json_response(:ok)

      resp["data"]
      |> Enum.each(& assert is_list &1["virtual_dates"])
    end

    test "applies with_virtual_points param", %{conn: conn} do
      resp =
        conn
        |> get(Routes.data_set_api_path(conn, :list, with_virtual_points: true))
        |> json_response(:ok)

      resp["data"]
      |> Enum.each(& assert is_list &1["virtual_points"])
    end

    test "applies bbox contains param", %{conn: conn} do
      geom = %Geo.Point{srid: 4326, coordinates: {1, 2}} |> Geo.JSON.encode() |> Jason.encode!()

      resp =
        conn
        |> get(Routes.data_set_api_path(conn, :list, bbox: "contains:#{geom}"))
        |> json_response(:ok)

      assert length(resp["data"]) == 0

      geom = %Geo.Point{srid: 4326, coordinates: {-87.8, 42.0}} |> Geo.JSON.encode() |> Jason.encode!()

      resp =
        conn
        |> get(Routes.data_set_api_path(conn, :list, bbox: "contains:#{geom}"))
        |> json_response(:ok)

      assert length(resp["data"]) == 1
      assert resp["meta"]["query"]["bbox_contains"] == %{
        "coordinates" => [-87.8, 42.0],
        "crs" => %{
          "properties" => %{"name" => "EPSG:4326"},
          "type" => "name"
        },
        "type" => "Point"
      }
    end

    test "applies bbox intersects param", %{conn: conn} do
      geom =
        %Geo.Polygon{
          srid: 4326,
          coordinates: [[
            {1, 1},
            {1, 2},
            {2, 2},
            {2, 1},
            {1, 1}
          ]]
        }
        |> Geo.JSON.encode()
        |> Jason.encode!()

      resp =
        conn
        |> get(Routes.data_set_api_path(conn, :list, bbox: "intersects:#{geom}"))
        |> json_response(:ok)

      assert length(resp["data"]) == 0

      geom =
        %Geo.Polygon{
          srid: 4326,
          coordinates: [[
            {-88.0, 41.0},
            {-88.0, 43.0},
            {-85.0, 43.0},
            {-85.0, 41.0},
            {-88.0, 41.0}
          ]]
        }
        |> Geo.JSON.encode()
        |> Jason.encode!()

      resp =
        conn
        |> get(Routes.data_set_api_path(conn, :list, bbox: "intersects:#{geom}"))
        |> json_response(:ok)

      assert length(resp["data"]) == 2
      assert resp["meta"]["query"]["bbox_intersects"] == %{
        "coordinates" => [
          [
            [-88.0, 41.0],
            [-88.0, 43.0],
            [-85.0, 43.0],
            [-85.0, 41.0],
            [-88.0, 41.0]
          ]
        ],
        "crs" => %{
          "properties" => %{"name" => "EPSG:4326"},
          "type" => "name"
        },
        "type" => "Polygon"
      }
    end

    test "applies time_range contains param", %{conn: conn} do
      timestamp = Timex.format!(NaiveDateTime.utc_now(), "{ISO:Extended:Z}")

      resp =
        conn
        |> get(Routes.data_set_api_path(conn, :list, time_range: "contains:#{timestamp}"))
        |> json_response(:ok)

      assert length(resp["data"]) == 0

      timestamp = Timex.format!(~N[2016-12-31 23:50:00], "{ISO:Extended:Z}")

      resp =
        conn
        |> get(Routes.data_set_api_path(conn, :list, time_range: "contains:#{timestamp}"))
        |> json_response(:ok)

      assert length(resp["data"]) == 1
      assert resp["meta"]["query"]["time_range_contains"] == timestamp
    end

    test "applies time_range intersects param", %{conn: conn} do
      range =
        Plenario.TsRange.new(~N[2000-01-01 00:00:00], ~N[2000-01-02 00:00:00])
        |> Jason.encode!()

      resp =
        conn
        |> get(Routes.data_set_api_path(conn, :list, time_range: "intersects:#{range}"))
        |> json_response(:ok)

      assert length(resp["data"]) == 0

      range =
        Plenario.TsRange.new(~N[2015-01-01 00:00:00], ~N[2018-01-01 00:00:00])
        |> Jason.encode!()

      resp =
        conn
        |> get(Routes.data_set_api_path(conn, :list, time_range: "intersects:#{range}"))
        |> json_response(:ok)

      assert length(resp["data"]) == 1
      assert resp["meta"]["query"]["time_range_intersects"] == %{
        "lower" => "2015-01-01T00:00:00",
        "lower_inclusive" => true,
        "upper" => "2018-01-01T00:00:00",
        "upper_inclusive" => true
      }
    end
  end

  describe "detail" do
    # TODO: when i'm not exhausted
  end

  describe "@aggregate" do
    # test "it serves the needs of the explorer app", %{conn: conn, crimes: crimes} do
    #   resp =
    #     conn
    #     |> get(Routes.data_set_api_path(conn, :aggregate, crimes))
    #     |> json_response(:ok)
    # end
  end
end
