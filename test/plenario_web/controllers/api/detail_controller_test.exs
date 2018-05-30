defmodule PlenarioWeb.Api.DetailControllerTest do
  use PlenarioWeb.Testing.ConnCase

  alias Plenario.{ModelRegistry, Repo}
  alias Plenario.Actions.{
    DataSetActions,
    DataSetFieldActions,
    MetaActions,
    UniqueConstraintActions,
    UserActions,
    VirtualPointFieldActions
  }

  alias Plenario.Schemas.{DataSetField, Meta, UniqueConstraint, User, VirtualPointField}

  import PlenarioWeb.Api.Utils, only: [truncate: 1]

  # Setting up the fixure data once _greatly_ reduces the test time. The downside is that in order to make this work
  # you must be explicit about database connection ownership and you must also clean up the tests yourself.
  setup_all do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, :auto)

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
    (1..100) |> Enum.each(fn _ ->
      Repo.insert(%{model.__struct__ | datetime: "2500-01-01 00:00:00", location: "(50, 50)"})
    end)

    # Registers a callback that runs once (because we're in setup_all) after all the tests have run. Use to clean up!
    # If things screw up and this isn't called properly, `env MIX_ENV=test mix ecto.drop` (bash) is your friend.
    on_exit(fn ->
      # Check out again because this callback is run in another process.
      :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
      Ecto.Adapters.SQL.Sandbox.mode(Repo, :auto)
      truncate([DataSetField, Meta, UniqueConstraint, User, VirtualPointField, model])
    end)

    %{slug: meta.slug(), vpf: vpf}
  end

  test "GET /api/v2/data-sets/:slug", %{slug: slug} do
    conn = get(build_conn(), "/api/v2/data-sets/#{slug}")
    response = json_response(conn, 200)
    assert length(response["data"]) == 100
  end

  test "GET /api/v2/data-sets/:slug/@head", %{slug: slug} do
    conn = get(build_conn(), "/api/v2/data-sets/#{slug}/@head")
    response = json_response(conn, 200)
    assert is_map(response["data"])
  end

  test "GET /api/v2/data-sets/:slug/@describe", %{slug: slug} do
    conn = get(build_conn(), "/api/v2/data-sets/#{slug}/@describe")
    response = json_response(conn, 200)
    assert length(response["data"]) == 100
  end

  test "GET /api/v2/data-sets/:slug pagination page parameter", %{slug: slug} do
    conn = get(build_conn(), "/api/v2/data-sets/#{slug}?page=2")
    response = json_response(conn, 200)
    assert length(response["data"]) == 0
    assert response["meta"]["counts"]["total_pages"] == 1
  end

  test "GET /api/v2/data-sets/:slug pagination page_size parameter", %{slug: slug} do
    conn = get(build_conn(), "/api/v2/data-sets/#{slug}?page_size=10")
    response = json_response(conn, 200)
    assert length(response["data"]) == 10
    assert response["meta"]["counts"]["total_pages"] == 10
  end

  test "GET /api/v2/data-sets/:slug pagination page and page_size parameters", %{slug: slug} do
    conn = get(build_conn(), "/api/v2/data-sets/#{slug}?page_size=5&page=2")
    response = json_response(conn, 200)
    assert length(response["data"]) == 5
    assert response["meta"]["params"]["page"] == "2"
    assert response["meta"]["params"]["page_size"] == 5
  end

  test "GET /api/v2/data-sets/:slug pagination is stable with backfills", %{slug: slug} do
    conn = get(build_conn(), "/api/v2/data-sets/#{slug}?page_size=5&page=2")
    response = json_response(conn, 200)

    assert length(response["data"]) == 5
    assert response["meta"]["params"]["page"] == "2"
    assert response["meta"]["params"]["page_size"] == 5
  end

  test "GET /api/v2/data-sets/:slug populates pagination links", %{slug: slug} do
    conn = get(build_conn(), "/api/v2/data-sets/#{slug}?page_size=5&page=2")
    response = json_response(conn, 200)

    assert length(response["data"]) == 5
    assert response["meta"]["links"]["current"] =~ "page_size=5&page=2"
    assert response["meta"]["links"]["current"] =~ "inserted_at"
    assert response["meta"]["links"]["previous"] =~ "page_size=5&page=1"
    assert response["meta"]["links"]["previous"] =~ "inserted_at"
    assert response["meta"]["links"]["next"] =~ "page_size=5&page=3"
    assert response["meta"]["links"]["next"] =~ "inserted_at"
  end

  test "OPTIONS /api/v2/data-sets/:slug status", %{conn: conn} do
    conn = options(conn, "/api/v2/data-sets")
    assert conn.status == 204
  end

  test "OPTIONS /api/v2/data-sets/:slug headers", %{conn: conn} do
    conn = options(conn, "/api/v2/data-sets")
    headers = Enum.into(conn.resp_headers, %{})
    assert headers["access-control-allow-methods"] == "GET,HEAD,OPTIONS"
    assert headers["access-control-allow-origin"] == "*"
    assert headers["access-control-max-age"] == "300"
  end

  test "GET /api/v2/data-sets/:slug bbox query", %{slug: slug} do
    geojson =
      """
      {
        "type": "Polygon",
        "coordinates": [
          [
            [0, 0],
            [0, 100],
            [100, 100],
            [100, 0],
            [0, 0]
          ]
        ]
      }
      """
    conn = get(build_conn(), "/api/v2/data-sets/#{slug}?bbox=#{geojson}")
    response = json_response(conn, 200)
    assert length(response["data"]) == 100
  end

  test "GET /api/v2/data-sets/:slug bbox query no results", %{slug: slug} do
    geojson =
      """
      {
        "type": "Polygon",
        "coordinates": [
          [
            [0, 0],
            [0, 1],
            [1, 1],
            [1, 0],
            [0, 0]
          ]
        ]
      }
      """
    conn = get(build_conn(), "/api/v2/data-sets/#{slug}?bbox=#{geojson}")
    response = json_response(conn, 200)
    assert length(response["data"]) == 0
  end

  test "GET /api/v2/data-sets/:slug range query", %{slug: slug} do
    conn = get(build_conn(), "/api/v2/data-sets/#{slug}?datetime=in:{\"upper\": \"3000-01-01\", \"lower\": \"2000-01-01\"}")
    response = json_response(conn, 200)
    assert length(response["data"]) == 100
  end

  test "GET /api/v2/data-sets/:slug range query no results", %{slug: slug} do
    conn = get(build_conn(), "/api/v2/data-sets/#{slug}?datetime=in:{\"upper\": \"2000-01-01\", \"lower\": \"3000-01-01\"}")
    response = json_response(conn, 200)
    assert length(response["data"]) == 0
  end

  test "GET /api/v2/data-sets/:slug location query", %{slug: slug, vpf: vpf} do
    geojson =
      """
      {
        "type": "Polygon",
        "coordinates": [
          [
            [0, 0],
            [0, 100],
            [100, 100],
            [100, 0],
            [0, 0]
          ]
        ]
      }
      """
    conn = get(build_conn(), "/api/v2/data-sets/#{slug}?#{vpf.id}=in:#{geojson}")
    response = json_response(conn, 200)
    assert length(response["data"]) == 100
  end

  test "GET /api/v2/data-sets/:slug location query no results", %{slug: slug, vpf: vpf} do
    geojson =
      """
      {
        "type": "Polygon",
        "coordinates": [
          [
            [0, 0],
            [0, 1],
            [1, 1],
            [1, 0],
            [0, 0]
          ]
        ]
      }
      """
    conn = get(build_conn(), "/api/v2/data-sets/#{slug}?#{vpf.name}=in:#{geojson}")
    response = json_response(conn, 200)
    assert length(response["data"]) == 0
  end

  test "page_size param cannot exceed 5000", %{slug: slug} do
    get(build_conn(), "/api/v2/data-sets/#{slug}?page_size=5001")
    |> json_response(422)
  end

  test "page_size param cannot be less than 1", %{slug: slug} do
    get(build_conn(), "/api/v2/data-sets/#{slug}?page_size=0")
    |> json_response(422)
  end

  test "page_size param cannot be negative", %{slug: slug} do
    get(build_conn(), "/api/v2/data-sets/#{slug}?page_size=-1")
    |> json_response(422)
  end

  test "page_size cannot be a string", %{slug: slug} do
    get(build_conn(), "/api/v2/data-sets/#{slug}?page_size=string")
    |> json_response(422)
  end

  test "valid page_size param", %{slug: slug} do
    get(build_conn(), "/api/v2/data-sets/#{slug}?page_size=501")
    |> json_response(200)
  end
end
