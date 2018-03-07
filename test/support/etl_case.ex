defmodule Plenario.Testing.EtlCase do
  @moduledoc """
  This module defines the setup for tests that need to interact with an existing
  dataset populated with fixture data. A test case using this module cannot be
  run in `async` mode.
  """

  use ExUnit.CaseTemplate

  alias Plenario.ModelRegistry
  alias Plenario.Actions.{
    DataSetActions,
    DataSetFieldActions,
    MetaActions,
    UniqueConstraintActions,
    UserActions
  }

  alias PlenarioEtl.{Exporter, Worker}

  import Ecto.Query

  using do
    quote do
      alias Plenario.Repo
      alias PlenarioEtl.{Exporter, Worker}
      alias PlenarioEtl.Actions.{DataSetActions, DataSetFieldActions, ExportJobActions}
      alias PlenarioEtl.Schemas.{ExportJob}

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Mock

      import Plenario.Testing.EtlCase
    end
  end

  @insert_rows [
    %{
      "data" => "crackers",
      "datetime" => "2017-01-01T00:00:00+00:00",
      "location" => "(0, 1)",
      "pk" => 1
    },
    %{
      "data" => "and",
      "datetime" => "2017-01-02T00:00:00+00:00",
      "location" => "(0, 2)",
      "pk" => 2
    },
    %{
      "data" => "cheese",
      "datetime" => "2017-01-03T00:00:00+00:00",
      "location" => "(0, 3)",
      "pk" => 3
    }
  ]

  setup_all _tags do
    Ecto.Adapters.SQL.Sandbox.checkout(Plenario.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Plenario.Repo, {:shared, self()})

    {:ok, user} = UserActions.create("Test User", "test@example.com", "password")
    {:ok, meta} = MetaActions.create("Test Dataset", user.id, "https://www.example.com", "csv")

    {:ok, pk} = DataSetFieldActions.create(meta.id, "pk", "integer")
    {:ok, _} = DataSetFieldActions.create(meta.id, "datetime", "timestamptz")
    {:ok, _} = DataSetFieldActions.create(meta.id, "location", "text")
    {:ok, _} = DataSetFieldActions.create(meta.id, "data", "text")
    {:ok, _} = UniqueConstraintActions.create(meta.id, [pk.id])

    DataSetActions.up!(meta)
    Worker.upsert!(meta, @insert_rows, [:pk])

    # Create export job fixture
    query = from(m in ModelRegistry.lookup(meta.slug))
    querystr = inspect(query, structs: false)
    {:ok, export_job} = PlenarioEtl.Actions.ExportJobActions.create(meta, user, querystr, false)

    %{meta: meta, user: user, export_job: export_job}
  end

end