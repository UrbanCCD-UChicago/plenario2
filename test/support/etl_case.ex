defmodule Plenario.Testing.EtlCase do
  use ExUnit.CaseTemplate

  alias Plenario.ModelRegistry

  alias Plenario.Actions.{
    UserActions,
    MetaActions,
    DataSetFieldActions,
    VirtualPointFieldActions
  }

  using do
    quote do
      alias Plenario.Repo
      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Plenario.Testing.EtlCase
    end
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Plenario.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Plenario.Repo, {:shared, self()})

    ModelRegistry.clear()

    {:ok, user} = UserActions.create("Test User", "test@example.com", "password")
    {:ok, meta} = MetaActions.create("Test data Set", user.id, "https://www.example.com/", "csv")
    {:ok, _} = MetaActions.update(meta, refresh_rate: "days", refresh_interval: 1, refresh_starts_on: NaiveDateTime.utc_now())
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
    {:ok, _} = VirtualPointFieldActions.create(meta, lat.id, lon.id)
    {:ok, _} = VirtualPointFieldActions.create(meta, loc.id)

    {:ok, user: user, meta: meta}
  end
end
