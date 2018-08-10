defmodule PlenarioWeb.Api.DetailControllerTest do
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

  @list_head_keys [
    "row_id",
    "DNA Test ID",
    "DNA Sample Timestamp",
    "Beach",
    "DNA Sample 1 Reading",
    "DNA Sample 2 Reading",
    "DNA Reading Mean",
    "Culture Test ID",
    "Culture Sample 1 Timestamp",
    "Culture Sample 1 Reading",
    "Culture Sample 2 Reading",
    "Culture Reading Mean",
    "Culture Note",
    "Culture Sample Interval",
    "Culture Sample 2 Timestamp",
    "Latitude",
    "Longitude",
    "Location"
  ]

  @describe_keys [
    "attribution",
    "bbox",
    "description",
    "fields",
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
    "virtual_dates",
    "virtual_points"
  ]

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

  @good_bbox_count 102

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
                     lower: ~N[2017-05-01 00:00:00],
                     upper: ~N[2017-06-01 00:00:00],
                     upper_inclusive: false
                   }
                   |> Poison.encode!()

  @good_time_range_count 113

  @nada_time_range %TsRange{
                     lower: ~N[2011-05-26 00:00:00],
                     upper: ~N[2012-05-26 00:00:00],
                     upper_inclusive: false
                   }
                   |> Poison.encode!()

  @bad_time_range "whenever"

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

  describe "GET detail endpoint" do
    test "will 404 when it can't find the slug", %{conn: conn} do
      conn
      |> get(detail_path(conn, :get, "i-dont-exist"))
      |> json_response(:not_found)
    end

    test "will 404 when given the id, even if it's for a valid, ready data set", %{
      conn: conn,
      meta: meta
    } do
      conn
      |> get(detail_path(conn, :get, meta.id))
      |> json_response(:not_found)
    end

    test "will 404 for a not-ready data set", %{conn: conn, user: user} do
      {:ok, meta} =
        MetaActions.create("not ready 2", user, "https://example.com/not-ready-2", "csv")

      conn
      |> get(detail_path(conn, :get, meta.id))
      |> json_response(:not_found)
    end

    test "each object contains the same keys", %{conn: conn, meta: meta} do
      res =
        conn
        |> get(detail_path(conn, :get, meta.slug))
        |> json_response(:ok)

      res["data"]
      |> Enum.with_index()
      |> Enum.each(fn {el, idx} ->
        next = Enum.at(res["data"], idx + 1)

        if next != nil do
          assert Map.keys(el) == Map.keys(next)
        end
      end)
    end

    test "each record exactly contains its `row_id`, columns, and virtual fields", %{
      conn: conn,
      meta: meta,
      vpf: vpf
    } do
      keys =
        (@list_head_keys ++ [vpf.name])
        |> Enum.sort()

      res =
        conn
        |> get(detail_path(conn, :get, meta.slug))
        |> json_response(:ok)

      res["data"]
      |> Enum.each(&assert Map.keys(&1) == keys)
    end
  end

  describe "filter results by bbox" do
    test "with a well formatted polygon", %{conn: conn, meta: meta, vpf: vpf} do
      res =
        conn
        |> get(detail_path(conn, :get, meta.slug, %{vpf.name => "within:#{@good_bbox}"}))
        |> json_response(:ok)

      assert length(res["data"]) == @good_bbox_count

      res =
        conn
        |> get(detail_path(conn, :get, meta.slug, %{vpf.name => "within:#{@nada_bbox}"}))
        |> json_response(:ok)

      assert length(res["data"]) == 0
    end

    test "will 400 with a poorly formatted polygon", %{conn: conn, meta: meta, vpf: vpf} do
      conn
      |> get(detail_path(conn, :get, meta.slug, %{vpf.name => "within:#{@bad_bbox}"}))
      |> json_response(:bad_request)
    end
  end

  describe "filter results by time range" do
    test "with a well formatted time range", %{conn: conn, meta: meta} do
      res =
        conn
        |> get(
          detail_path(conn, :get, meta.slug, %{
            "DNA Sample Timestamp": "within:#{@good_time_range}"
          })
        )
        |> json_response(:ok)

      assert length(res["data"]) == @good_time_range_count

      res =
        conn
        |> get(
          detail_path(conn, :get, meta.slug, %{
            "DNA Sample Timestamp": "within:#{@nada_time_range}"
          })
        )
        |> json_response(:ok)

      assert length(res["data"]) == 0
    end

    test "will 400 with a poorly formatted time range", %{conn: conn, meta: meta} do
      conn
      |> get(
        detail_path(conn, :get, meta.slug, %{"DNA Sample Timestamp": "in:#{@bad_time_range}"})
      )
      |> json_response(:bad_request)
    end
  end

  describe "GET @head endpoint" do
    test "it only returns the first record of the data set", %{conn: conn, meta: meta} do
      res =
        conn
        |> get(detail_path(conn, :head, meta.slug, %{order_by: "asc:DNA Sample Timestamp"}))
        |> json_response(:ok)

      assert length(res["data"]) == 1

      asc =
        res["data"]
        |> List.first()

      res =
        conn
        |> get(detail_path(conn, :head, meta.slug, %{order_by: "desc:DNA Sample Timestamp"}))
        |> json_response(:ok)

      assert length(res["data"]) == 1

      desc =
        res["data"]
        |> List.first()

      assert asc != desc
      assert asc["DNA Sample Timestamp"] < desc["DNA Sample Timestamp"]
    end

    test "will 404 when it can't find the slug", %{conn: conn} do
      conn
      |> get(detail_path(conn, :get, "i-dont-exist"))
      |> json_response(:not_found)
    end

    test "will 404 when given the id, even if it's for a valid, ready data set", %{
      conn: conn,
      meta: meta
    } do
      conn
      |> get(detail_path(conn, :get, meta.id))
      |> json_response(:not_found)
    end

    test "will 404 for a not-ready data set", %{conn: conn, user: user} do
      {:ok, meta} = MetaActions.create("not readu", user, "https://example.com/not-ready", "csv")

      conn
      |> get(detail_path(conn, :get, meta.id))
      |> json_response(:not_found)
    end

    test "each object contains the same keys", %{conn: conn, meta: meta} do
      res =
        conn
        |> get(detail_path(conn, :get, meta.slug))
        |> json_response(:ok)

      res["data"]
      |> Enum.with_index()
      |> Enum.each(fn {el, idx} ->
        next = Enum.at(res["data"], idx + 1)

        if next != nil do
          assert Map.keys(el) == Map.keys(next)
        end
      end)
    end

    test "each record exactly contains its `row_id`, columns, and virtual fields", %{
      conn: conn,
      meta: meta,
      vpf: vpf
    } do
      keys =
        (@list_head_keys ++ [vpf.name])
        |> Enum.sort()

      res =
        conn
        |> get(detail_path(conn, :get, meta.slug))
        |> json_response(:ok)

      res["data"]
      |> Enum.each(&assert Map.keys(&1) == keys)
    end
  end

  describe "GET @describe endpoint" do
    test "the response object exactly contains meta information and field information", %{
      conn: conn,
      meta: meta
    } do
      res =
        conn
        |> get(detail_path(conn, :describe, meta.slug))
        |> json_response(:ok)

      assert Map.keys(res["data"]) == @describe_keys
    end
  end
end
