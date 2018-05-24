defmodule Plenario.Testing.Actions.DataSetActionsTest do
  use ExUnit.Case

  alias Plenario.{ModelRegistry, Repo}

  alias Plenario.Actions.{
    UserActions,
    MetaActions,
    DataSetFieldActions,
    VirtualPointFieldActions,
    DataSetActions
  }

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Plenario.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Plenario.Repo, {:shared, self()})

    ModelRegistry.clear()

    {:ok, user} = UserActions.create("name", "email@example.com", "password")
    {:ok, meta} = MetaActions.create("name", user, "https://example.com/", "csv")
    {:ok, _} = DataSetFieldActions.create(meta, "DNA Test ID", "text")
    {:ok, _} = DataSetFieldActions.create(meta, "DNA Sample Timestamp", "timestamptz")
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
    {:ok, _} = DataSetFieldActions.create(meta, "Location", "text")
    {:ok, _} = VirtualPointFieldActions.create(meta, lat.id, lon.id)

    {:ok, [meta: meta]}
  end

  test "up!", %{meta: meta} do
    :ok = DataSetActions.up!(meta)
  end

  test "down!", %{meta: meta} do
    :ok = DataSetActions.up!(meta)
    :ok = DataSetActions.down!(meta)
  end

  test "etl!", %{meta: meta} do
    fixture = "test/fixtures/beach-lab-dna.csv"
    contents = File.read!(fixture)
    path = "/tmp/beach-dna.csv"
    File.write!(path, contents)

    :ok = DataSetActions.up!(meta)
    :ok = DataSetActions.etl!(meta, path, delimiter: ",", headers?: true)

    model = ModelRegistry.lookup(meta.slug)
    records = Repo.all(model)
    assert length(records) == 2936

    # check that it truncates and uses fresh data

    fixture = "test/fixtures/beach-lab-dna-one-line.csv"
    contents = File.read!(fixture)
    path = "/tmp/beach-dna.csv"
    File.write!(path, contents)

    :ok = DataSetActions.etl!(meta, path, delimiter: ",", headers?: true)

    model = ModelRegistry.lookup(meta.slug)
    records = Repo.all(model)
    assert length(records) == 1
  end
end
