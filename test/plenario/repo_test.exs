defmodule Plenario.Testing.RepoTest do
  use Plenario.Testing.DataCase

  alias Plenario.{
    Repo,
    TableModelRegistry,
    ViewModelRegistry
  }

  setup do
    TableModelRegistry.clear()
    ViewModelRegistry.clear()

    user = create_user()
    data_set = create_data_set(%{user: user})
    _ = create_field(%{data_set: data_set}, name: "id")
    _ = create_field(%{data_set: data_set}, name: "location", type: "geometry")

    {:ok, data_set: data_set}
  end

  describe "up!" do
    test "creates a table", %{data_set: data_set} do
      :ok = Repo.up!(data_set)

      model = TableModelRegistry.lookup(data_set)
      Repo.all(model)
    end

    test "creates a view", %{data_set: data_set} do
      :ok = Repo.up!(data_set)

      model = ViewModelRegistry.lookup(data_set)
      Repo.all(model)
    end
  end

  describe "down!" do
    test "drops the table", %{data_set: data_set} do
      :ok = Repo.up!(data_set)
      :ok = Repo.down!(data_set)

      assert_raise Postgrex.Error, fn ->
        model = TableModelRegistry.lookup(data_set)
        Repo.all(model)
      end
    end

    test "drops the view", %{data_set: data_set} do
      :ok = Repo.up!(data_set)
      :ok = Repo.down!(data_set)

      assert_raise Postgrex.Error, fn ->
        model = ViewModelRegistry.lookup(data_set)
        Repo.all(model)
      end
    end
  end

  describe "etl!" do
    test "completely refreshes the data from a local source document", %{data_set: data_set} do
      :ok = Repo.up!(data_set)

      :ok = Repo.etl!(data_set, "test/fixtures/id_location.csv")

      model = ViewModelRegistry.lookup(data_set)
      count = Repo.all(model) |> Enum.count()
      assert count == 8

      :ok = Repo.etl!(data_set, "test/fixtures/id_location_refresh.csv")

      model = ViewModelRegistry.lookup(data_set)
      count = Repo.all(model) |> Enum.count()
      assert count == 2
    end
  end
end
