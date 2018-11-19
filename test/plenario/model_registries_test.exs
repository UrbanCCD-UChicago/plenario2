defmodule Plenario.Testing.ModelRegistriesTest do
  use Plenario.Testing.DataCase

  import Geo.PostGIS, only: [st_contains: 2]

  import Ecto.Query

  alias Plenario.{
    TableModelRegistry,
    ViewModelRegistry,
    Repo
  }

  setup do
    TableModelRegistry.clear()
    ViewModelRegistry.clear()

    user = create_user()
    data_set = create_data_set(%{user: user})
    _ = create_field(%{data_set: data_set}, name: "id")
    _ = create_field(%{data_set: data_set}, name: "location", type: "geometry")

    :ok = Repo.up!(data_set)

    {:ok, data_set: data_set}
  end

  describe "Table Model Registry" do
    test "lookup returns an atom", %{data_set: data_set} do
      model = TableModelRegistry.lookup(data_set)
      assert model == :"TableModels.test_data_set"
    end

    test "can construct a query with the atom returned from lookup", %{data_set: data_set} do
      :ok = Repo.etl!(data_set, "test/fixtures/id_location.csv")

      model = TableModelRegistry.lookup(data_set)
      count = Repo.all(model)
      assert length(count) == 8
    end
  end

  describe "View Model Registry" do
    test "lookup returns an atom", %{data_set: data_set} do
      model = ViewModelRegistry.lookup(data_set)
      assert model == :"ViewModels.test_data_set_view"
    end

    test "can construct a query with the atom returned from lookup", %{data_set: data_set} do
      :ok = Repo.etl!(data_set, "test/fixtures/id_location.csv")

      model = ViewModelRegistry.lookup(data_set)

      count = Repo.all(model)
      assert length(count) == 8

      geom = %Geo.Polygon{
        srid: 4326,
        coordinates: [[
          {0, 5},
          {5, 5},
          {5, 0},
          {0, 0},
          {0, 5}
        ]]
      }
      records = Repo.all(from m in model, where: st_contains(^geom, m.location))
      assert length(records) == 8

      geom = %Geo.Polygon{
        srid: 4326,
        coordinates: [[
          {0, -5},
          {5, -5},
          {5, 0},
          {0, 0},
          {0, -5}
        ]]
      }
      records = Repo.all(from m in model, where: st_contains(^geom, m.location))
      assert length(records) == 0
    end
  end
end
