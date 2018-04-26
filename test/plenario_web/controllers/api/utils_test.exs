defmodule PlenarioWeb.Api.UtilsTest do
  use ExUnit.Case, async: true
  import PlenarioWeb.Api.Utils

  alias Plenario.{ModelRegistry, Repo}
  alias Plenario.Actions.{
    DataSetActions,
    DataSetFieldActions,
    MetaActions,
    UniqueConstraintActions,
    UserActions,
    VirtualPointFieldActions
  }

  setup do
    Ecto.Adapters.SQL.Sandbox.checkout(Plenario.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Plenario.Repo, {:shared, self()})

    {:ok, user} = UserActions.create("API Test User", "test@example.com", "password")
    {:ok, meta} = MetaActions.create("API Test Dataset", user.id, "https://www.example.com", "csv")
    {:ok, pk} = DataSetFieldActions.create(meta.id, "pk", "integer")
    {:ok, _} = DataSetFieldActions.create(meta.id, "datetime", "timestamptz")
    {:ok, _} = DataSetFieldActions.create(meta.id, "data", "text")
    {:ok, location} = DataSetFieldActions.create(meta.id, "location", "text")
    {:ok, vpf} = VirtualPointFieldActions.create(meta, location.id)
    {:ok, _} = UniqueConstraintActions.create(meta.id, [pk.id])

    DataSetActions.up!(meta)

    # Insert 100 empty rows
    ModelRegistry.clear()
    model = ModelRegistry.lookup(meta.slug())
    (1..50) |> Enum.each(fn _ ->
      Repo.insert(%{model.__struct__ | datetime: ~N[2000-01-01 00:00:00]})
    end)

    (50..100) |> Enum.each(fn _ ->
      Repo.insert(%{model.__struct__ | datetime: ~N[2000-01-02 00:00:00]})
    end)


    (100..120) |> Enum.each(fn _ ->
      Repo.insert(%{model.__struct__ | location: "(50, 50)"})
    end)

    # vpf: virtual point field
    %{slug: meta.slug(), vpf: vpf}
  end

  test "map_to_query/2", %{slug: slug} do
    query_map = %{
      "inserted_at" => {"le", ~N[2000-01-01 13:30:15]},
      "updated_at" => {"lt", ~N[2000-01-01 13:30:15]},
      "float_column" => {"ge", 0.0},
      "integer_column" => {"gt", 42},
      "string_column" => {"eq", "hello!"}
    }

    ModelRegistry.lookup(slug)
    |> map_to_query(query_map)
  end

  test "generates a geospatial query using a bounding box", %{slug: slug, vpf: vpf} do
    # vpf: virtual point field

    model = ModelRegistry.lookup(slug)
    polygon = %Geo.Polygon{
      coordinates: [[{0, 0}, {0, 100}, {100, 100}, {100, 0}, {0, 0}]],
      srid: 4326
    }

    query = where_condition(model, {vpf.name, {"in", polygon}})

    results = Repo.all(query)

    assert length(results) == 21
  end

  test "generates a ranged query using bounding values", %{slug: slug} do
    model = ModelRegistry.lookup(slug)
    query = where_condition(model, {"datetime", {"in", %{
      lower: ~N[2000-01-01 00:00:00],
      upper: ~N[2000-01-01 12:00:00]
    }}})

    results = Repo.all(query)

    assert length(results) == 50
  end
end
