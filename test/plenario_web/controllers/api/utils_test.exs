defmodule PlenarioWeb.Api.UtilsTest do
  use ExUnit.Case
  import PlenarioWeb.Api.Utils

  # todo(heyzoos) all this could be pushed up to the conn test helper when we
  # eventually reintegrate it
  alias Plenario.{ModelRegistry, Repo}

  alias Plenario.Actions.{
    DataSetActions,
    DataSetFieldActions,
    MetaActions,
    UserActions,
    VirtualPointFieldActions
  }

  setup do
    Ecto.Adapters.SQL.Sandbox.checkout(Plenario.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Plenario.Repo, {:shared, self()})

    {:ok, user} = UserActions.create("API Test User", "test@example.com", "password")
    {:ok, meta} = MetaActions.create("API Test Dataset", user.id, "https://www.example.com", "csv")
    {:ok, _} = DataSetFieldActions.create(meta.id, "pk", "integer")
    {:ok, _} = DataSetFieldActions.create(meta.id, "datetime", "timestamp")
    {:ok, _} = DataSetFieldActions.create(meta.id, "data", "text")
    {:ok, location} = DataSetFieldActions.create(meta.id, "location", "text")
    {:ok, vpf} = VirtualPointFieldActions.create(meta, location.id)

    DataSetActions.up!(meta)

    ModelRegistry.clear()

    insert = """
    INSERT INTO "#{meta.table_name}"
      (pk, datetime, data, location)
    VALUES
      (1, '2000-01-01 00:00:00', null, null),
      (2, '2000-01-01 00:00:00', null, null),
      (3, '2000-01-01 00:00:00', null, null),
      (4, '2000-01-01 00:00:00', null, null),
      (5, '2000-01-01 00:00:00', null, null),
      (6, '2000-01-02 00:00:00', null, null),
      (7, '2000-01-02 00:00:00', null, null),
      (8, '2000-01-02 00:00:00', null, null),
      (9, '2000-01-02 00:00:00', null, null),
      (10, '2000-01-02 00:00:00', null, null),
      (11, null, null, '(50, 50)'),
      (12, null, null, '(50, 50)'),
      (13, null, null, '(50, 50)'),
      (14, null, null, '(50, 50)'),
      (15, null, null, '(50, 50)');
    """
    Ecto.Adapters.SQL.query!(Repo, insert)

    refresh = """
    REFRESH MATERIALIZED VIEW "#{meta.table_name}_view";
    """
    Ecto.Adapters.SQL.query!(Repo, refresh)

    %{slug: meta.slug(), vpf: vpf}
  end

  test "map_to_query/2", %{slug: slug} do
    model = ModelRegistry.lookup(slug)
    query_map = %{
      "float_column" => {"ge", 0.0},
      "integer_column" => {"gt", 42},
      "string_column" => {"eq", "hello!"}
    }

    map_to_query(model, query_map)
  end

  test "generates a geospatial query using a bounding box", %{slug: slug, vpf: vpf} do
    model = ModelRegistry.lookup(slug)
    polygon = %Geo.Polygon{
      coordinates: [[{0, 0}, {0, 100}, {100, 100}, {100, 0}, {0, 0}]],
      srid: 4326
    }

    query = where_condition(model, {vpf.name, {"in", polygon}})

    results = Repo.all(query)

    assert length(results) == 5
  end

  test "generates a ranged query using bounding values", %{slug: slug} do
    model = ModelRegistry.lookup(slug)
    query = where_condition(model, {"datetime", {"in", %{
      "lower" => "2000-01-01 00:00:00",
      "upper" => "2000-01-01 12:00:00"
    }}})

    results = Repo.all(query)

    assert length(results) == 5
  end
end
