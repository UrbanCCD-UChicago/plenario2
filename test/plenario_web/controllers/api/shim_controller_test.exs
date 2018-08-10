# defmodule PlenarioWeb.Api.ShimControllerTest do
#   use ExUnit.Case

#   use Phoenix.ConnTest

#   alias Plenario.ModelRegistry

#   alias Plenario.Actions.{
#     DataSetActions,
#     DataSetFieldActions,
#     MetaActions,
#     UserActions,
#     VirtualPointFieldActions
#   }

#   @fixutre "test/fixtures/beach-lab-dna.csv"

#   @endpoint PlenarioWeb.Endpoint

#   setup do
#     Ecto.Adapters.SQL.Sandbox.checkout(Plenario.Repo)
#     Ecto.Adapters.SQL.Sandbox.mode(Plenario.Repo, {:shared, self()})

#     ModelRegistry.clear()

#     {:ok, user} = UserActions.create("Test User", "test@example.com", "password")
#     {:ok, meta} = MetaActions.create("Chicago Beach Lab - DNA Tests", user.id, "https://example.com/", "csv")
#     {:ok, _} = DataSetFieldActions.create(meta, "DNA Test ID", "text")
#     {:ok, _} = DataSetFieldActions.create(meta, "DNA Sample Timestamp", "timestamp")
#     {:ok, _} = DataSetFieldActions.create(meta, "Beach", "text")
#     {:ok, _} = DataSetFieldActions.create(meta, "DNA Sample 1 Reading", "float")
#     {:ok, _} = DataSetFieldActions.create(meta, "DNA Sample 2 Reading", "float")
#     {:ok, _} = DataSetFieldActions.create(meta, "DNA Reading Mean", "float")
#     {:ok, _} = DataSetFieldActions.create(meta, "Culture Test ID", "text")
#     {:ok, _} = DataSetFieldActions.create(meta, "Culture Sample 1 Timestamp", "text")
#     {:ok, _} = DataSetFieldActions.create(meta, "Culture Sample 1 Reading", "text")
#     {:ok, _} = DataSetFieldActions.create(meta, "Culture Sample 2 Reading", "text")
#     {:ok, _} = DataSetFieldActions.create(meta, "Culture Reading Mean", "text")
#     {:ok, _} = DataSetFieldActions.create(meta, "Culture Note", "text")
#     {:ok, _} = DataSetFieldActions.create(meta, "Culture Sample Interval", "text")
#     {:ok, _} = DataSetFieldActions.create(meta, "Culture Sample 2 Timestamp", "text")
#     {:ok, lat} = DataSetFieldActions.create(meta, "Latitude", "float")
#     {:ok, lon} = DataSetFieldActions.create(meta, "Longitude", "float")
#     {:ok, _} = DataSetFieldActions.create(meta, "Location", "text")
#     {:ok, vpf} = VirtualPointFieldActions.create(meta, lat.id, lon.id)

#     {:ok, meta} = MetaActions.submit_for_approval(meta)
#     {:ok, meta} = MetaActions.approve(meta)
#     :ok = DataSetActions.etl!(meta, @fixutre)
#     {:ok, meta} = MetaActions.mark_first_import(meta)
#     {:ok, meta} = MetaActions.update_latest_import(meta, NaiveDateTime.utc_now())
#     bbox = MetaActions.compute_bbox!(meta)
#     {:ok, meta} = MetaActions.update_bbox(meta, bbox)
#     range = MetaActions.compute_time_range!(meta)
#     {:ok, meta} = MetaActions.update_time_range(meta, range)

#     {:ok, meta: meta, vpf: vpf, conn: build_conn(), user: user}
#   end

#   test "GET /api/v1/datasets", %{conn: conn} do
#     get(conn, "/api/v1/datasets")
#     |> json_response(200)
#   end

#   test "GET /api/v1/detail", %{conn: conn, meta: meta} do
#     get(conn, "/api/v1/detail?dataset_name=#{meta.slug}")
#     |> json_response(200)
#   end

#   test "GET /api/v1/detail has no 'dataset_name'", %{conn: conn} do
#     get(conn, "/api/v1/detail")
#     |> json_response(422)
#   end

#   test "GET /api/v1/detail __ gt", %{conn: conn, meta: meta} do
#     get(conn, "/api/v1/detail?dataset_name=#{meta.slug}")
#     |> json_response(200)
#   end

#   test "GET /v1/api/detail", %{conn: conn, meta: meta} do
#     get(conn, "/v1/api/detail?dataset_name=#{meta.slug}")
#     |> json_response(200)
#   end

#   test "GET /v1/api/detail has no 'dataset_name'", %{conn: conn} do
#     get(conn, "/v1/api/detail")
#     |> json_response(422)
#   end

#   test "GET /v1/api/detail __ ge", %{conn: conn, meta: meta} do
#     result =
#       get(conn, "/v1/api/detail?dataset_name=#{meta.slug}&DNA+Sample+Timestamp__ge=2500-01-01T00:00:00")
#       |> json_response(200)

#     assert length(result["objects"]) == 0

#     result =
#       get(conn, "/v1/api/detail?dataset_name=#{meta.slug}&DNA+Sample+Timestamp__ge=2000-01-02T00:00:00")
#       |> json_response(200)

#     assert length(result["objects"]) == 500
#   end

#   test "GET /v1/api/detail __gt", %{conn: conn, meta: meta} do
#     result =
#       get(conn, "/v1/api/detail?dataset_name=#{meta.slug}&DNA+Sample+Timestamp__gt=2500-01-01T00:00:00")
#       |> json_response(200)

#     assert length(result["objects"]) == 0

#     result =
#       get(conn, "/v1/api/detail?dataset_name=#{meta.slug}&DNA+Sample+Timestamp__gt=2000-01-02T00:00:00")
#       |> json_response(200)

#     assert result["meta"]["total"] == 2936
#   end

#   test "GET /v1/api/detail __lt", %{conn: conn, meta: meta} do
#     result =
#       get(conn, "/v1/api/detail?dataset_name=#{meta.slug}&DNA+Sample+Timestamp__lt=2500-01-01T00:00:00")
#       |> json_response(200)

#     assert length(result["objects"]) == 500

#     result =
#       get(conn, "/v1/api/detail?dataset_name=#{meta.slug}&DNA+Sample+Timestamp__lt=2000-01-02T00:00:00")
#       |> json_response(200)

#     assert length(result["objects"]) == 0
#   end

#   test "GET /v1/api/detail __le", %{conn: conn, meta: meta} do
#     result =
#       get(conn, "/v1/api/detail?dataset_name=#{meta.slug}&DNA+Sample+Timestamp__le=2500-01-01T00:00:00")
#       |> json_response(200)

#     assert length(result["objects"]) == 500

#     result =
#       get(conn, "/v1/api/detail?dataset_name=#{meta.slug}&DNA+Sample+Timestamp__le=2000-01-02T00:00:00")
#       |> json_response(200)

#     assert length(result["objects"]) == 0
#   end

#   test "GET /api/v1/detail __eq", %{conn: conn, meta: meta} do
#     result =
#       get(conn, "/v1/api/detail?dataset_name=#{meta.slug}&DNA+Sample+Timestamp__eq=2500-01-02T00:00:00")
#       |> json_response(200)

#     assert length(result["objects"]) == 0
#   end

#   test "GET /v1/api/datasets", %{conn: conn} do
#     result = json_response(get(conn, "/api/v1/datasets"), 200)
#     assert length(result["objects"]) == 1
#   end

#   test "GET /v1/api/datasets doesn't blow up when a ready data set doens't have a time range", %{conn: conn, user: user} do
#     {:ok, meta} = MetaActions.create("edge case", user, "https://example.com/edge-case", "csv")
#     {:ok, meta} = MetaActions.submit_for_approval(meta)
#     {:ok, meta} = MetaActions.approve(meta)
#     {:ok, meta} = MetaActions.mark_first_import(meta)
#     {:ok, _} = MetaActions.update_latest_import(meta, NaiveDateTime.utc_now())

#     result =
#       conn
#       |> get("/v1/api/datasets")
#       |> json_response(200)

#     assert length(result["objects"]) == 2
#   end

#   test "GET /api/v1/datasets has correct count", %{conn: conn} do
#     result = json_response(get(conn, "/api/v1/datasets"), 200)
#     assert result["meta"]["total"] == 1
#   end

#   test "GET /v1/api/datasets __ge", %{conn: conn} do
#     result = json_response(get(conn, "/api/v1/datasets?latest_import__ge=2000-01-03T00:00:00"), 200)
#     assert result["meta"]["total"] == 1
#   end

#   test "GET /v1/api/datasets __gt", %{conn: conn} do
#     result = json_response(get(conn, "/api/v1/datasets?latest_import__gt=2000-01-03T00:00:00"), 200)
#     assert result["meta"]["total"] == 1
#   end

#   test "GET /v1/api/datasets __le", %{conn: conn} do
#     result = json_response(get(conn, "/api/v1/datasets?latest_import__le=2000-01-03T00:00:00"), 200)
#     assert result["meta"]["total"] == 0
#   end

#   test "GET /v1/api/datasets __lt", %{conn: conn} do
#     result = json_response(get(conn, "/api/v1/datasets?latest_import__lt=2000-01-03T00:00:00"), 200)
#     assert result["meta"]["total"] == 0

#     result = json_response(get(conn, "/api/v1/datasets?latest_import__lt=2500-01-03T00:00:00"), 200)
#     assert result["meta"]["total"] == 1
#   end

#   test "GET /v1/api/datasets __eq", %{conn: conn, meta: meta} do
#     result = json_response(get(conn, "/api/v1/datasets?latest_import__eq=#{meta.latest_import}"), 200)
#     assert result["meta"]["total"] == 1
#   end

#   test "GET /v1/api/detail obs_date", %{conn: conn, meta: meta} do
#     result =
#       conn
#       |> get("/api/v1/detail"
#         <> "?dataset_name=#{meta.slug}"
#         <> "&obs_date__le=2500-01-01T00:00:00")
#       |> json_response(200)

#     assert result["meta"]["total"] == 2936
#     assert length(result["objects"]) == 500
#   end

#   test "GET /v1/api/detail location_geom__within", %{conn: conn, meta: meta} do
#     geom =
#       """
#       {
#         "type":"Polygon",
#         "coordinates":[
#            [
#               [0.0, 0.0],
#               [0.0, 125.0],
#               [125.0, 125.0],
#               [125.0, 0.0],
#               [0.0, 0.0]
#            ]
#         ]
#       }
#       """

#     result =
#       conn
#       |> get("/api/v1/detail"
#         <> "?dataset_name=#{meta.slug}"
#         <> "&location_geom__within=#{geom}")
#       |> json_response(200)

#     assert result["meta"]["total"] == 0
#     assert length(result["objects"]) == 0
#   end

#   test "GET /v1/api/detail obs_date & geom", %{conn: conn, meta: meta} do
#     geom =
#       %{
#         "coordinates" => [
#           [
#             [100, 100],
#             [-100, 100],
#             [-100, -100],
#             [100, -100],
#             [100, 100]
#           ]
#         ],
#         "type" => "Polygon"
#       }
#       |> Poison.encode!()

#     result =
#       conn
#       |> get("/api/v1/detail"
#         <> "?dataset_name=#{meta.slug}"
#         <> "&location_geom__within=#{geom}"
#         <> "&obs_date__ge=1970-01-01T00:00:00")
#       |> json_response(200)

#     assert result["meta"]["total"] == 2864
#   end

#   # test "V1 format special columns for metas at /datasets endpoint", %{vpf: vpf} do
#   #   result =
#   #     build_conn()
#   #     |> get("/api/v1/datasets")
#   #     |> json_response(200)
#   #
#   #   meta = Enum.find(result["objects"], fn
#   #     m -> m["dataset_name"] == "api-test-dataset"
#   #   end)
#   #
#   #   assert meta["observed_date"] == "datetime"
#   #   assert meta["location"] == vpf.name
#   # end

#   test "V1 keyword offset behaves like page for datasets" do
#     result =
#       build_conn()
#       |> get("/api/v1/datasets?limit=1&offset=2")
#       |> json_response(200)

#     assert length(result["objects"]) == 0
#   end

#   test "V1 keyword limit behaves like page_size for datasets" do
#     result =
#       build_conn()
#       |> get("/api/v1/datasets?limit=2")
#       |> json_response(200)

#     assert length(result["objects"]) == 1
#   end

#   test "V1 keyword offset behaves like page for detail", %{meta: meta} do
#     result =
#       build_conn()
#       |> get("/api/v1/detail?dataset_name=#{meta.slug}&offset=4&limit=1")
#       |> json_response(200)

#     [first_record | _ ] = result["objects"]

#     assert first_record["DNA Test ID"] == "2009"
#   end

#   test "V1 keyword limit behaves like page_size for detail", %{meta: meta} do
#     result =
#       build_conn()
#       |> get("/api/v1/detail?dataset_name=#{meta.slug}&limit=2")
#       |> json_response(200)

#     assert length(result["objects"]) == 2
#   end
# end
