defmodule PlenarioWeb.Api.ShimControllerTest do
  use ExUnit.Case
  use Phoenix.ConnTest

  import PlenarioWeb.Api.Utils, only: [truncate: 1]

  alias Plenario.{
    DataSetField,
    ModelRegistry,
    Repo
  }

  alias Plenario.Actions.{
    DataSetActions,
    DataSetFieldActions,
    MetaActions,
    UniqueConstraintActions,
    UserActions,
    VirtualPointFieldActions
  }

  alias Plenario.Schemas.{
    DataSetField,
    Meta,
    UniqueConstraint,
    User,
    VirtualPointField
  }

  alias PlenarioAot.{
    AotActions,
    AotData,
    AotMeta
  }

  @aot_fixture_path "test/fixtures/aot-chicago-future.json"
  @endpoint PlenarioWeb.Endpoint

  # Setting up the fixure data once _greatly_ reduces the test time. The
  # downside is that in order to make this work you must be explicit about
  # database connection ownership and you must also clean up tests yourself.
  setup_all do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, :auto)

    # Set up fixture data for /data-sets and /data-sets/:slug
    {:ok, user} = UserActions.create("API Test User", "test@example.com", "password")
    {:ok, meta} = MetaActions.create("API Test Dataset", user.id, "https://www.example.com", "csv")
    {:ok, pk} = DataSetFieldActions.create(meta.id, "pk", "integer")
    {:ok, _} = DataSetFieldActions.create(meta.id, "datetime", "timestamptz")
    {:ok, location} = DataSetFieldActions.create(meta.id, "location", "text")
    {:ok, _} = DataSetFieldActions.create(meta.id, "data", "text")
    {:ok, vpf} = VirtualPointFieldActions.create(meta, location.id)
    {:ok, _} = UniqueConstraintActions.create(meta.id, [pk.id])

    DataSetActions.up!(meta)

    # Insert 100 empty rows
    ModelRegistry.clear()
    model = ModelRegistry.lookup(meta.slug())
    (1..75) |> Enum.each(fn _ ->
      Repo.insert(%{model.__struct__ | datetime: "2500-01-01 00:00:00", location: "(50, 50)"})
    end)

    (76..100) |> Enum.each(fn _ ->
      Repo.insert(%{model.__struct__ | datetime: "2500-01-02 00:00:00", location: "(50, 50)"})
    end)

    (1..5) |> Enum.each(fn i ->
      {:ok, m} = MetaActions.create("META #{i}", user.id, "https://www.example.com/#{i}", "csv")
      MetaActions.update_latest_import(m, NaiveDateTime.from_iso8601!("2000-01-0#{i}T00:00:00"))
    end)

    {:ok, aot_meta} = AotActions.create_meta("Chicago", "https://example.com/")

    File.read!(@aot_fixture_path)
    |> Poison.decode!()
    |> Enum.map(fn obj -> AotActions.insert_data(aot_meta, obj) end)

    AotActions.compute_and_update_meta_bbox(aot_meta)
    AotActions.compute_and_update_meta_time_range(aot_meta)

    # Registers a callback that runs once (because we're in setup_all) after
    # all the tests have run. Use to clean up! If things screw up and this
    # isn't called properly, `env MIX_ENV=test mix ecto.drop` (bash) is your
    # friend.
    on_exit(fn ->
      # Check out again because this callback is run in another process.
      :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
      Ecto.Adapters.SQL.Sandbox.mode(Repo, :auto)
      truncate([DataSetField, Meta, UniqueConstraint, User, VirtualPointField, model])
      truncate([AotMeta, AotData])
    end)

    %{
      meta: meta,
      vpf: vpf,
      conn: build_conn()
    }
  end

  test "GET /api/v1/datasets", %{conn: conn} do
    get(conn, "/api/v1/datasets")
    |> json_response(200)
  end

  test "GET /api/v1/detail", %{conn: conn, meta: meta} do
    get(conn, "/api/v1/detail?dataset_name=#{meta.slug}")
    |> json_response(200)
  end

  test "GET /api/v1/detail has no 'dataset_name'", %{conn: conn} do
    get(conn, "/api/v1/detail")
    |> json_response(422)
  end

  test "GET /api/v1/detail __ gt", %{conn: conn, meta: meta} do
    get(conn, "/api/v1/detail?dataset_name=#{meta.slug}")
    |> json_response(200)
  end

  test "GET /v1/api/detail", %{conn: conn, meta: meta} do
    get(conn, "/v1/api/detail?dataset_name=#{meta.slug}")
    |> json_response(200)
  end

  test "GET /v1/api/detail has no 'dataset_name'", %{conn: conn} do
    get(conn, "/v1/api/detail")
    |> json_response(422)
  end

  test "GET /v1/api/detail __ ge", %{conn: conn, meta: meta} do
    result =
      get(conn, "/v1/api/detail?dataset_name=#{meta.slug}&datetime__ge=2500-01-01")
      |> json_response(200)

    assert length(result["data"]) == 100

    result =
      get(conn, "/v1/api/detail?dataset_name=#{meta.slug}&datetime__ge=2500-01-02")
      |> json_response(200)

    assert length(result["data"]) == 25 
  end

  test "GET /v1/api/detail __gt", %{conn: conn, meta: meta} do
    result =
      get(conn, "/v1/api/detail?dataset_name=#{meta.slug}&datetime__gt=2500-01-01")
      |> json_response(200)

    assert length(result["data"]) == 25

    result =
      get(conn, "/v1/api/detail?dataset_name=#{meta.slug}&datetime__gt=2500-01-02")
      |> json_response(200)

    assert length(result["data"]) == 0 
  end

  test "GET /v1/api/detail __lt", %{conn: conn, meta: meta} do
    result =
      get(conn, "/v1/api/detail?dataset_name=#{meta.slug}&datetime__lt=2500-01-01")
      |> json_response(200)

    assert length(result["data"]) == 0

    result =
      get(conn, "/v1/api/detail?dataset_name=#{meta.slug}&datetime__lt=2500-01-02")
      |> json_response(200)

    assert length(result["data"]) == 75 
  end

  test "GET /v1/api/detail __le", %{conn: conn, meta: meta} do
    result =
      get(conn, "/v1/api/detail?dataset_name=#{meta.slug}&datetime__le=2500-01-01")
      |> json_response(200)

    assert length(result["data"]) == 75 

    result =
      get(conn, "/v1/api/detail?dataset_name=#{meta.slug}&datetime__le=2500-01-02")
      |> json_response(200)

    assert length(result["data"]) == 100
  end

  test "GET /api/v1/detail __eq", %{conn: conn, meta: meta} do
    result =
      get(conn, "/v1/api/detail?dataset_name=#{meta.slug}&datetime__eq=2500-01-02")
      |> json_response(200)

    assert length(result["data"]) == 25
  end

  test "GET /v1/api/datasets", %{conn: conn} do
    result = json_response(get(conn, "/api/v1/datasets"), 200)
    assert length(result["data"]) == 6
  end

  test "GET /api/v1/datasets has correct count", %{conn: conn} do
    result = json_response(get(conn, "/api/v1/datasets"), 200)
    assert result["meta"]["counts"]["total_records"] == 6
  end

  test "GET /v1/api/datasets __ge", %{conn: conn} do
    result = json_response(get(conn, "/api/v1/datasets?latest_import__ge=2000-01-03T00:00:00"), 200)
    assert result["meta"]["counts"]["total_records"] == 3
  end

  test "GET /v1/api/datasets __gt", %{conn: conn} do
    result = json_response(get(conn, "/api/v1/datasets?latest_import__gt=2000-01-03T00:00:00"), 200)
    assert result["meta"]["counts"]["total_records"] == 2
  end

  test "GET /v1/api/datasets __le", %{conn: conn} do
    result = json_response(get(conn, "/api/v1/datasets?latest_import__le=2000-01-03T00:00:00"), 200)
    assert result["meta"]["counts"]["total_records"] == 3
  end

  test "GET /v1/api/datasets __lt", %{conn: conn} do
    result = json_response(get(conn, "/api/v1/datasets?latest_import__lt=2000-01-03T00:00:00"), 200)
    assert result["meta"]["counts"]["total_records"] == 2
  end

  test "GET /v1/api/datasets __eq", %{conn: conn} do
    result = json_response(get(conn, "/api/v1/datasets?latest_import__eq=2000-01-03T00:00:00"), 200)
    assert result["meta"]["counts"]["total_records"] == 1
  end
end