defmodule PlenarioWeb.Api.UtilsTest do
  use ExUnit.Case, async: true
  import PlenarioWeb.Api.Utils

  alias Plenario.{ModelRegistry, Repo}
  alias Plenario.Actions.{
    DataSetActions,
    DataSetFieldActions,
    MetaActions,
    UniqueConstraintActions,
    UserActions
  }

  setup do
    Ecto.Adapters.SQL.Sandbox.checkout(Plenario.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Plenario.Repo, {:shared, self()})

    {:ok, user} = UserActions.create("API Test User", "test@example.com", "password")
    {:ok, meta} = MetaActions.create("API Test Dataset", user.id, "https://www.example.com", "csv")
    {:ok, pk} = DataSetFieldActions.create(meta.id, "pk", "integer")
    {:ok, _} = DataSetFieldActions.create(meta.id, "datetime", "timestamptz")
    {:ok, _} = DataSetFieldActions.create(meta.id, "location", "text")
    {:ok, _} = DataSetFieldActions.create(meta.id, "data", "text")
    {:ok, _} = UniqueConstraintActions.create(meta.id, [pk.id])

    DataSetActions.up!(meta)

    # Insert 100 empty rows
    ModelRegistry.clear()
    model = ModelRegistry.lookup(meta.slug())
    (1..100) |> Enum.each(fn _ -> Repo.insert(model.__struct__) end)

    %{slug: meta.slug()}
  end

  test "map_to_query/2", %{slug: slug} do
    query_map = %{
      "inserted_at" => {"le", ~N[2000-01-01 13:30:15]},
      "updated_at" => {"le", ~N[2000-01-01 13:30:15]}
    }

    query =
      ModelRegistry.lookup(slug)
      |> map_to_query(query_map)
      |> IO.inspect()
  end

  test "tuple_to_where_condition/1", %{slug: slug} do
    tuple_condition = {"datetime_column", {"le", ~N[2000-01-01 13:30:15]}}
    query =
      ModelRegistry.lookup(slug)
      |> tuple_to_where_condition(tuple_condition)
      |> IO.inspect()
  end
end
