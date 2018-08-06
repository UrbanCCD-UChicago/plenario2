defmodule PlenarioWeb.Api.ListControllerTest do
  use ExUnit.Case

  use Phoenix.ConnTest

  import PlenarioWeb.Router.Helpers

  alias Geo.Polygon

  alias Plenario.{
    ModelRegistry,
    TsRange
  }

  alias Plenario.Actions.{
    UserActions,
    MetaActions,
    DataSetFieldActions,
    VirtualPointFieldActions,
    DataSetActions
  }

  @endpoint PlenarioWeb.Endpoint

  @fixutre "test/fixtures/beach-lab-dna.csv"

  @list_head_keys [
    "attribution",
    "bbox",
    "description",
    "first_import",
    "latest_import",
    "name",
    "next_import",
    "refresh_ends_on",
    "refresh_interval",
    "refresh_rate",
    "refresh_starts_on",
    "slug",
    "source_url",
    "time_range",
    "user"
  ]

  @describe_keys [
    "attribution",
    "bbox",
    "description",
    "first_import",
    "latest_import",
    "name",
    "next_import",
    "refresh_ends_on",
    "refresh_interval",
    "refresh_rate",
    "refresh_starts_on",
    "slug",
    "source_url",
    "time_range",
    "user",
    "fields",
    "virtual_date_fields",
    "virtual_point_fields"
  ]

  @good_bbox %Polygon{
               coordinates: [
                 [
                   {42.5, -87.8},
                   {41.5, -87.8},
                   {41.5, -87.4},
                   {42.5, -87.4},
                   {42.5, -87.8}
                 ]
               ],
               srid: 4326
             }
             |> Geo.JSON.encode()
             |> Poison.encode!()

  @nada_bbox %Polygon{
               coordinates: [
                 [
                   {1, 1},
                   {1, -1},
                   {-1, -1},
                   {-1, 1},
                   {1, 1}
                 ]
               ],
               srid: 4326
             }
             |> Geo.JSON.encode()
             |> Poison.encode!()

  @bad_bbox "the-moon"

  @good_time_range %TsRange{
                     lower: ~N[2016-05-26 00:00:00],
                     upper: ~N[2017-05-26 00:00:00],
                     upper_inclusive: false
                   }
                   |> Poison.encode!()

  @nada_time_range %TsRange{
                     lower: ~N[2011-05-26 00:00:00],
                     upper: ~N[2012-05-26 00:00:00],
                     upper_inclusive: false
                   }
                   |> Poison.encode!()

  @bad_time_range "whenever"

  setup do
    Ecto.Adapters.SQL.Sandbox.checkout(Plenario.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Plenario.Repo, {:shared, self()})

    ModelRegistry.clear()

    {:ok, user} = UserActions.create("Test User", "test@example.com", "password")

    {:ok, meta} =
      MetaActions.create("Chicago Beach Lab - DNA Tests", user.id, "https://example.com/", "csv")

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

  describe "GET list endpoint" do
    test "it returns only _ready_ data sets", %{conn: conn, user: user} do
      # create a new data set, but don't move it along in workflow
      {:ok, _} = MetaActions.create("not ready", user, "http://example.com/not-ready/", "csv")

      res =
        conn
        |> get(list_path(conn, :get))
        |> json_response(:ok)

      assert length(res["data"]) == 1

      res["data"]
      |> Enum.each(&(&1["state"] == "ready"))
    end

    test "each object in data only contains meta information", %{conn: conn} do
      res =
        conn
        |> get(list_path(conn, :get))
        |> json_response(:ok)

      res["data"]
      |> Enum.each(&assert Map.keys(&1) == @list_head_keys)
    end
  end

  describe "filter list endpoint by bbox" do
    test "with a well formatted polygon", %{conn: conn} do
      res =
        conn
        |> get(list_path(conn, :get, %{bbox: @good_bbox}))
        |> json_response(:ok)

      assert length(res["data"]) == 1

      res =
        conn
        |> get(list_path(conn, :get, %{bbox: @nada_bbox}))
        |> json_response(:ok)

      assert length(res["data"]) == 0
    end

    test "will 400 with a poorly formatter polygon", %{conn: conn} do
      conn
      |> get(list_path(conn, :get, %{bbox: @bad_bbox}))
      |> json_response(:bad_request)
    end
  end

  describe "filter list endpoint by time range" do
    test "with a well formatted time range", %{conn: conn} do
      res =
        conn
        |> get(list_path(conn, :get, %{time_range: "in:#{@good_time_range}"}))
        |> json_response(:ok)

      assert length(res["data"]) == 1

      res =
        conn
        |> get(list_path(conn, :get, %{time_range: "in:#{@nada_time_range}"}))
        |> json_response(:ok)

      assert length(res["data"]) == 0
    end

    test "will 400 with a poorly formatted time range", %{conn: conn} do
      conn
      |> get(list_path(conn, :get, %{time_range: "in:#{@bad_time_range}"}))
      |> json_response(:bad_request)
    end
  end

  describe "GET @head endpoint" do
    test "it returns only the first ready data set", %{conn: conn, user: user} do
      res =
        conn
        |> get(list_path(conn, :head))
        |> json_response(:ok)

      assert length(res["data"]) == 1

      # create a new data set, but don't move it along in workflow
      {:ok, _} = MetaActions.create("not ready", user, "http://example.com/not-ready/", "csv")

      res =
        conn
        |> get(list_path(conn, :head))
        |> json_response(:ok)

      assert length(res["data"]) == 1
    end

    test "each object in data only contains meta information", %{conn: conn} do
      res =
        conn
        |> get(list_path(conn, :head))
        |> json_response(:ok)

      res["data"]
      |> Enum.each(&assert Map.keys(&1) == @list_head_keys)
    end
  end

  describe "GET @describe endpoint" do
    test "it returns only _ready_ data sets", %{conn: conn, user: user} do
      # create a new data set, but don't move it along in workflow
      {:ok, _} = MetaActions.create("not ready", user, "http://example.com/not-ready/", "csv")

      res =
        conn
        |> get(list_path(conn, :describe))
        |> json_response(:ok)

      assert length(res["data"]) == 1
    end

    test "each object in data contains both meta information and details about fields", %{
      conn: conn
    } do
      res =
        conn
        |> get(list_path(conn, :describe))
        |> json_response(:ok)

      res["data"]
      |> Enum.each(&assert Map.keys(&1) == @describe_keys)
    end
  end
end
