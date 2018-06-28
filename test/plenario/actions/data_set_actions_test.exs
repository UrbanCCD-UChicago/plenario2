defmodule Plenario.Actions.DataSetActionsTest do
  use Plenario.Testing.DataCase

  alias Plenario.{Repo, ModelRegistry}

  alias Plenario.Actions.{
    DataSetActions,
    DataSetFieldActions,
    VirtualPointFieldActions
  }

  setup %{meta: meta} do
    ModelRegistry.clear()

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
    {:ok, loc} = DataSetFieldActions.create(meta, "Location", "text")
    {:ok, _} = VirtualPointFieldActions.create(meta, loc.id)
    {:ok, _} = VirtualPointFieldActions.create(meta, lat.id, lon.id)

    :ok
  end

  test "up!", %{meta: meta} do
    :ok = DataSetActions.up!(meta)
  end

  test "down!", %{meta: meta} do
    :ok = DataSetActions.up!(meta)
    :ok = DataSetActions.down!(meta)
  end

  test "etl!", %{meta: meta} do
    :ok = DataSetActions.up!(meta)
    :ok = DataSetActions.etl!(meta, "test/fixtures/beach-lab-dna.csv")

    model = ModelRegistry.lookup(meta.slug)
    res = Repo.all(model)
    assert length(res) == 2936

    first = List.first(res) |> Map.from_struct()
    assert first[:"DNA Reading Mean"] == 79.7
    assert first[:"DNA Sample 1 Reading"] == 39.0
    assert first[:"DNA Sample 2 Reading"] == 163.0
    assert first[:"DNA Sample Timestamp"] == ~N[2016-08-05 12:35:00.000000]
    assert first[:"Latitude"] == 41.9655
    assert first[:"Longitude"] == -87.6385
    assert first[:"row_id"] == 1

    for {key, value} <- first do
      key = Atom.to_string(key)
      if String.starts_with?(key, "vpf_") do
        assert value == %Geo.Point{
          coordinates: {-87.6385, 41.9655},
          srid: 4326
        }
      end
    end
  end
end
