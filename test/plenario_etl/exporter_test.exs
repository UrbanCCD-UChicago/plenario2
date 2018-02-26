defmodule PlenarioEtl.ExporterTest do
  use Plenario.Testing.DataCase

  alias Plenario.ModelRegistry

  alias Plenario.Actions.{
    DataSetActions,
    DataSetFieldActions,
    MetaActions,
    UniqueConstraintActions,
    UserActions
  }

  alias PlenarioEtl.{Exporter, Worker}
  alias PlenarioEtl.Actions.ExportJobActions
  alias PlenarioEtl.Schemas.ExportJob

  import Ecto.Query
  import Mock

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

  setup context do
    # Prevent cross contamination between tests
    ModelRegistry.clear()

    # Set up user, metadata, and dataset
    {:ok, meta} = MetaActions.create("test", context.user.id(), "http://example.com", "csv")
    {:ok, pk_field} = DataSetFieldActions.create(meta.id, "pk", "integer")
    {:ok, _} = DataSetFieldActions.create(meta.id, "datetime", "timestamptz")
    {:ok, _} = DataSetFieldActions.create(meta.id, "location", "text")
    {:ok, _} = DataSetFieldActions.create(meta.id, "data", "text")
    {:ok, _} = UniqueConstraintActions.create(meta.id, [pk_field.id])
    DataSetActions.up!(meta)

    # Preload the dataset with usable information
    Worker.upsert!(meta, @insert_rows, [:pk])

    # Set up the export job
    query = from(m in ModelRegistry.lookup(meta.slug))
    querystr = inspect(query, structs: false)
    {:ok, job} = ExportJobActions.create(meta, context.user, querystr, false)
    job = Repo.preload(job, [:meta, :user])

    %{job: job}
  end

  test "export/1 async api", %{job: job} do
    with_mock ExAws, request!: fn _a, _b -> :ok end do
      {:ok, task} = Exporter.export_task(job)
      Task.await(task)
    end

    job = Repo.one!(from(e in ExportJob, where: e.id == ^job.id))
    assert job.state == "completed"
  end

  test "export/1 completes", %{job: job} do
    with_mock ExAws, request!: fn _a, _b -> :ok end do
      Exporter.export(job)
    end

    job = Repo.one!(from(e in ExportJob, where: e.id == ^job.id))

    assert job.state == "completed"
  end

  test "export/1 errs", %{job: job} do
    with_mock ExAws, request!: fn _a, _b -> throw("Intentional Error") end do
      Exporter.export(job)
    end

    job = Repo.one!(from(e in ExportJob, where: e.id == ^job.id))

    assert job.state == "erred"
    assert job.error_message =~ "Intentional Error"
  end

  test "export/1 sends email upon success", context do
    with_mock ExAws, request!: fn _a, _b -> :ok end do
      {job, email} = Exporter.export(context.job)

      assert email.from == "plenario@uchicago.edu"
      assert email.to == context.user.email
      assert email.subject == "Plenario Notification"
      assert email.text_body =~ "Success!"
      assert email.html_body == nil
    end
  end

  test "export/1 sends email upon failure", context do
    with_mock ExAws, request!: fn _a, _b -> throw("Intentional Error") end do
      {job, email} = Exporter.export(context.job)
      assert email.from == "plenario@uchicago.edu"
      assert email.to == context.user.email
      assert email.subject == "Plenario Notification"
      assert email.text_body =~ "errored"
      assert email.html_body == nil
    end
  end
end
