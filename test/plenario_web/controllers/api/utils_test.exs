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
    AotData,
    AotMeta
  }

  setup_all do
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
      Repo.insert(%{model.__struct__ | datetime: "2000-01-01 00:00:00"})
    end)

    (50..100) |> Enum.each(fn _ ->
      Repo.insert(%{model.__struct__ | datetime: "2000-01-02 00:00:00"})
    end)

    (100..120) |> Enum.each(fn _ ->
      Repo.insert(%{model.__struct__ | location: "(50, 50)"})
    end)

    # Registers a callback that runs once (because we're in setup_all) after 
    # all the tests have run. Use to clean up! If things screw up and this 
    # isn't called properly, `env MIX_ENV=test mix ecto.drop` (bash) is your 
    # friend.
    on_exit(fn ->
      # Check out again because this callback is run in another process.
      :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
      Ecto.Adapters.SQL.Sandbox.mode(Repo, :auto)
      truncate([DataSetField, Meta, UniqueConstraint, User, VirtualPointField])
      truncate([AotMeta, AotData])
    end)

    %{
      model: model,
      vpf: vpf  # virtual point field
    }
  end

  test "map_to_query/2", %{model: model} do
    query_map = %{
      "inserted_at" => {"le", "2000-01-01 13:30:15"},
      "updated_at" => {"lt", "2000-01-01 13:30:15"},
      "float_column" => {"ge", 0.0},
      "integer_column" => {"gt", 42},
      "string_column" => {"eq", "hello!"}
    }

    map_to_query(model, query_map)
  end

  test "generates a geospatial query using a bounding box", %{model: model, vpf: vpf} do
    polygon = %Geo.Polygon{
      coordinates: [[{0, 0}, {0, 100}, {100, 100}, {100, 0}, {0, 0}]],
      srid: 4326
    }

    query = where_condition(model, {vpf.name, {"in", polygon}})

    results = Repo.all(query)

    assert length(results) == 21
  end

  test "generates a ranged query using bounding values", %{model: model} do
    query = where_condition(model, {"datetime", {"in", %{
      "lower" => "2000-01-01 00:00:00",
      "upper" => "2000-01-01 12:00:00"
    }}})

    results = Repo.all(query)

    assert length(results) == 50
  end
end
