defmodule PlenarioWeb.Api.PlugsTest do
  use ExUnit.Case

  use Phoenix.ConnTest

  import PlenarioWeb.Router.Helpers

  alias Geo.Polygon

  alias Plenario.{
    ModelRegistry,
    TsRange
  }

  alias Plenario.Actions.{
    DataSetActions,
    DataSetFieldActions,
    MetaActions,
    UserActions,
    VirtualPointFieldActions
  }

  @endpoint PlenarioWeb.Endpoint

  @fixutre "test/fixtures/beach-lab-dna.csv"

  @good_bbox %Polygon{
               coordinates: [
                 [
                   {-87.65449, 41.9878},
                   {-87.65451, 41.9878},
                   {-87.65451, 41.9876},
                   {-87.65449, 41.9876},
                   {-87.65449, 41.9878}
                 ]
               ],
               srid: 4326
             }
             |> Geo.JSON.encode()
             |> Poison.encode!()

  setup_all do
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

    {:ok, conn: build_conn(), user: user, meta: meta, vpf: vpf}
  end

  describe "check_page_size" do
    test "when not given a value will default to 200", %{conn: conn, meta: meta} do
      res =
        conn
        |> get(detail_path(conn, :get, meta.slug))
        |> json_response(:ok)

      assert res["meta"]["params"]["page_size"] == 200
    end

    test "when given a value too large will :forbidden", %{conn: conn, meta: meta} do
      conn
      |> get(detail_path(conn, :get, meta.slug, %{page_size: 1_000_000}))
      |> json_response(:forbidden)
    end

    test "when given a value too little will :unprocessable_entity", %{conn: conn, meta: meta} do
      conn
      |> get(detail_path(conn, :get, meta.slug, %{page_size: 0}))
      |> json_response(:unprocessable_entity)
    end

    test "when given a value not an integer will :bad_request", %{conn: conn, meta: meta} do
      conn
      |> get(detail_path(conn, :get, meta.slug, %{page_size: "1.1"}))
      |> json_response(:bad_request)
    end

    test "when given an integer between 0 and 5000 will :ok", %{conn: conn, meta: meta} do
      conn
      |> get(detail_path(conn, :get, meta.slug, %{page_size: 500}))
      |> json_response(:ok)
    end
  end

  describe "check_page" do
    test "when not give a value will default to 1", %{conn: conn, meta: meta} do
      res =
        conn
        |> get(detail_path(conn, :get, meta.slug))
        |> json_response(:ok)

      assert res["meta"]["params"]["page"] == 1
    end

    test "when given a value too little will :unprocessable_entity", %{conn: conn, meta: meta} do
      conn
      |> get(detail_path(conn, :get, meta.slug, %{page: -1}))
      |> json_response(:unprocessable_entity)
    end

    test "when given a value not an integer will :bad_request", %{conn: conn, meta: meta} do
      conn
      |> get(detail_path(conn, :get, meta.slug, %{page: "1.1"}))
      |> json_response(:bad_request)
    end

    test "when given a positive integer will :ok", %{conn: conn, meta: meta} do
      conn
      |> get(detail_path(conn, :get, meta.slug, %{page: "3"}))
      |> json_response(:ok)
    end
  end

  describe "check_order_by" do
    test "when not given a value will default to whatever was given in opts", %{
      conn: conn,
      meta: meta
    } do
      res =
        conn
        |> get(detail_path(conn, :get, meta.slug))
        |> json_response(:ok)

      assert res["meta"]["params"]["order_by"] == %{"asc" => "row_id"}

      res =
        conn
        |> get(list_path(conn, :get))
        |> json_response(:ok)

      assert res["meta"]["params"]["order_by"] == %{"asc" => "name"}
    end

    test "when given a value without a direction will :bad_request", %{conn: conn, meta: meta} do
      conn
      |> get(detail_path(conn, :get, meta.slug, %{order_by: "row_id"}))
      |> json_response(:bad_request)
    end

    test "when given a value with an unknown direction will :bad_request", %{
      conn: conn,
      meta: meta
    } do
      conn
      |> get(detail_path(conn, :get, meta.slug, %{order_by: "up:row_id"}))
      |> json_response(:bad_request)
    end

    test "when given a value with a valid direction but an unknow field will :bad_request", %{
      conn: conn,
      meta: meta
    } do
      conn
      |> get(detail_path(conn, :get, meta.slug, %{order_by: "desc:barf"}))
      |> json_response(:bad_request)
    end

    test "when given a value with a valid direction and field name will :ok", %{
      conn: conn,
      meta: meta
    } do
      conn
      |> get(detail_path(conn, :get, meta.slug, %{order_by: "desc:DNA Sample Timestamp"}))
      |> json_response(:ok)
    end
  end

  # NOTE: these tests also cover PlenarioWeb.Api.Utils, or at least all
  # of the query things. Everything else in that module gets touched
  # by the direct controller tests.

  describe "check_filters" do
    test "when given an unknown field will :bad_request", %{conn: conn, meta: meta} do
      conn
      |> get(detail_path(conn, :get, meta.slug, %{"latitude" => "lt:41.8"}))
      |> json_response(:bad_request)
    end

    test "lt", %{conn: conn, meta: meta} do
      res =
        conn
        |> get(detail_path(conn, :get, meta.slug, %{"Latitude" => "lt:41.8"}))
        |> json_response(:ok)

      assert res["meta"]["counts"]["total_records"] == 1005
    end

    test "le", %{conn: conn, meta: meta} do
      res =
        conn
        |> get(detail_path(conn, :get, meta.slug, %{"Latitude" => "le:41.8"}))
        |> json_response(:ok)

      assert res["meta"]["counts"]["total_records"] == 1005
    end

    test "eq", %{conn: conn, meta: meta} do
      res =
        conn
        |> get(detail_path(conn, :get, meta.slug, %{"Latitude" => "eq:41.8935"}))
        |> json_response(:ok)

      assert res["meta"]["counts"]["total_records"] == 173
    end

    test "naked param converted to eq", %{conn: conn, meta: meta} do
      res =
        conn
        |> get(detail_path(conn, :get, meta.slug, %{"Latitude" => "41.8935"}))
        |> json_response(:ok)

      assert res["meta"]["counts"]["total_records"] == 173
    end

    test "ge", %{conn: conn, meta: meta} do
      res =
        conn
        |> get(detail_path(conn, :get, meta.slug, %{"Latitude" => "ge:41.8"}))
        |> json_response(:ok)

      assert res["meta"]["counts"]["total_records"] == 1859
    end

    test "gt", %{conn: conn, meta: meta} do
      res =
        conn
        |> get(detail_path(conn, :get, meta.slug, %{"Latitude" => "gt:41.8"}))
        |> json_response(:ok)

      assert res["meta"]["counts"]["total_records"] == 1859
    end

    test "in", %{conn: conn, meta: meta} do
      res =
        conn
        |> get(detail_path(conn, :get, meta.slug, %{"Latitude" => ["41.8935", "41.758"]}))
        |> json_response(:ok)

      assert res["meta"]["counts"]["total_records"] == 400
    end

    test "within tsrange", %{conn: conn, meta: meta} do
      range =
        TsRange.new(~N[2017-01-01 00:00:00], ~N[2018-01-01 00:00:00], upper_inc: false)
        |> Poison.encode!()

      res =
        conn
        |> get(detail_path(conn, :get, meta.slug, %{"DNA Sample Timestamp" => "within:#{range}"}))
        |> json_response(:ok)

      assert res["meta"]["counts"]["total_records"] == 2022
    end

    test "within polygon", %{conn: conn, meta: meta, vpf: vpf} do
      res =
        conn
        |> get(detail_path(conn, :get, meta.slug, %{vpf.name => "within:#{@good_bbox}"}))
        |> json_response(:ok)

      assert res["meta"]["counts"]["total_records"] == 102
    end

    test "when given a within op but an unparseable value will :bad_request", %{
      conn: conn,
      meta: meta
    } do
      conn
      |> get(
        detail_path(conn, :get, meta.slug, %{"DNA Sample Timestamp" => "within:the last week"})
      )
      |> json_response(:bad_request)
    end

    test "intersects tsrange", %{conn: conn} do
      range =
        TsRange.new(~N[2017-01-01 00:00:00], ~N[2018-01-01 00:00:00], upper_inc: false)
        |> Poison.encode!()

      res =
        conn
        |> get(list_path(conn, :get, %{"time_range" => "intersects:#{range}"}))
        |> json_response(:ok)

      assert res["meta"]["counts"]["total_records"] == 1
    end

    test "intersects polygon", %{conn: conn} do
      res =
        conn
        |> get(list_path(conn, :get, %{"bbox" => "intersects:#{@good_bbox}"}))
        |> json_response(:ok)

      assert res["meta"]["counts"]["total_records"] == 1
    end

    test "when given a intersects op but an unparseable value will :bad_request", %{
      conn: conn
    } do
      conn
      |> get(list_path(conn, :get, %{"time_range" => "intersects:the past year"}))
      |> json_response(:bad_request)
    end
  end

  describe "check_format" do
    test "defualts to json", %{conn: conn} do
      res =
        conn
        |> get(list_path(conn, :get))
        |> json_response(:ok)

      assert res["meta"]["params"]["format"] == "json"
    end

    test "accepts geojson", %{conn: conn} do
      conn
      |> get(list_path(conn, :get, %{format: "geojson"}))
      |> json_response(:ok)
    end

    test "will 400 when given an unknown value", %{conn: conn} do
      conn
      |> get(list_path(conn, :get, %{format: "tsv"}))
      |> json_response(:bad_request)
    end
  end
end
