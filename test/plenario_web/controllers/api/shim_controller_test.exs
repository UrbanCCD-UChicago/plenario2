defmodule PlenarioWeb.Api.ShimControllerTest do
  use ExUnit.Case, async: true

  use Phoenix.ConnTest

  import PlenarioWeb.Router.Helpers

  alias Geo.Polygon

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

  @good_date "2017-05-01"

  @nada_date "1900-01-01"

  @bad_date "whenever"

  @num_fields 18

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

  describe "GET /datasets" do
    test "should only return _ready_ data sets", %{conn: conn} do
      res =
        conn
        |> get(shim_path(conn, :datasets))
        |> json_response(:ok)

      assert length(res["objects"]) == 1
    end

    test "with a known dataset_name filter should be ok", %{conn: conn, meta: meta} do
      res =
        conn
        |> get(shim_path(conn, :datasets, %{dataset_name: meta.slug}))
        |> json_response(:ok)

      assert length(res["objects"]) == 1
    end

    test "with a known old-formatted slug filter should be ok", %{conn: conn, meta: meta} do
      slug = meta.slug |> String.replace("-", "_")

      res =
        conn
        |> get(shim_path(conn, :datasets, %{dataset_name: slug}))
        |> json_response(:ok)

      assert length(res["objects"]) == 1
    end

    test "with a good geom should be ok", %{conn: conn} do
      res =
        conn
        |> get(shim_path(conn, :datasets, %{location_geom__within: @good_bbox}))
        |> json_response(:ok)

      assert length(res["objects"]) == 1

      res =
        conn
        |> get(shim_path(conn, :datasets, %{location_geom__within: @nada_bbox}))
        |> json_response(:ok)

      assert length(res["objects"]) == 0
    end

    test "with a bad geom will 400", %{conn: conn} do
      conn
      |> get(shim_path(conn, :datasets, %{location_geom__within: @bad_bbox}))
      |> json_response(:bad_request)
    end

    test "with a good date should be ok", %{conn: conn} do
      res =
        conn
        |> get(shim_path(conn, :datasets, %{obs_date__ge: @good_date}))
        |> json_response(:ok)

      assert length(res["objects"]) == 1

      res =
        conn
        |> get(shim_path(conn, :datasets, %{obs_date__le: @nada_date}))
        |> json_response(:ok)

      assert length(res["objects"]) == 0
    end

    test "with a bad date should 400", %{conn: conn} do
      conn
      |> get(shim_path(conn, :datasets, %{obs_date__ge: @bad_date}))
      |> json_response(:bad_request)
    end
  end

  describe "GET /fields" do
    test "with a known data set will be ok", %{conn: conn, meta: meta} do
      res =
        conn
        |> get(shim_path(conn, :fields, meta.slug))
        |> json_response(:ok)

      assert length(res["objects"]) == @num_fields
    end

    test "with an unknown slug will 404", %{conn: conn} do
      conn
      |> get(shim_path(conn, :fields, "garbage"))
      |> json_response(:not_found)
    end
  end

  describe "GET /detail" do
    test "will 404 when it can't find the slug given in the params", %{conn: conn} do
      conn
      |> get(shim_path(conn, :detail, %{dataset_name: "nope"}))
      |> json_response(:not_found)
    end

    test "will 404 when it doesn't get a slug in the params", %{conn: conn} do
      conn
      |> get(shim_path(conn, :detail))
      |> json_response(:not_found)
    end

    test "will 404 for a non-ready data set", %{conn: conn, user: user} do
      {:ok, meta} = MetaActions.create("not ready", user, "https://example.com/nope", "csv")

      conn
      |> get(shim_path(conn, :detail, %{dataset_name: meta.slug}))
      |> json_response(:not_found)
    end

    test "will return ok when a good slug is sent", %{conn: conn, meta: meta} do
      res =
        conn
        |> get(shim_path(conn, :detail, %{dataset_name: meta.slug}))
        |> json_response(:ok)

      assert length(res["objects"]) == 200
    end
  end
end
