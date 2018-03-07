defmodule PlenarioEtl.ExporterTest do
  use Plenario.Testing.EtlCase
  use Bamboo.Test

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
    insert_sql = """
    INSERT INTO <%= table_name %>
      ("data", "datetime", "location", "pk")
      VALUES
        ('crackers', '2017-01-01T00:00:00+00:00', '(0, 1)', 1),
        ('and', '2017-01-02T00:00:00+00:00', '(0, 2)', 2),
        ('cheese', '2017-01-03T00:00:00+00:00', '(0, 3)', 3)
    """
    sql = EEx.eval_string(insert_sql, [table_name: meta.table_name], trim: true)
    Ecto.Adapters.SQL.query(Plenario.Repo, sql)

    # Set up the export job
    query = from(m in ModelRegistry.lookup(meta.slug))
    querystr = inspect(query, structs: false)
    {:ok, job} = ExportJobActions.create(meta, context.user, querystr, false)
    job = Repo.preload(job, [:meta, :user])

    %{export_job: job}
  end

  test "export/1 async api", %{export_job: job} do
    with_mock ExAws, request!: fn _a, _b -> :ok end do
      {:ok, task} = Exporter.export_task(job)
      Task.await(task)
    end

    job = Repo.one!(from(e in ExportJob, where: e.id == ^job.id))

    assert job.state == "completed"
  end

  test "export/1 completes", %{export_job: job} do
    with_mock ExAws, request!: fn _a, _b -> :ok end do
      Exporter.export(job)
    end

    job = Repo.one!(from(e in ExportJob, where: e.id == ^job.id))

    assert job.state == "completed"
  end

  test "export/1 errs", %{export_job: job} do
    with_mock ExAws, request!: fn _a, _b -> throw("Intentional Error") end do
      Exporter.export(job)
    end

    job = Repo.one!(from(e in ExportJob, where: e.id == ^job.id))

    assert job.state == "erred"
    assert job.error_message =~ "Intentional Error"
  end

  test "export/1 success email", context do
    with_mock ExAws, request!: fn _a, _b -> :ok end do
      {_job, email} = Exporter.export(context.export_job)

      assert email.from == {nil, "plenario@uchicago.edu"}
      assert email.to == [nil: context.user.email]
      assert email.subject == "Plenario Notification"
      assert email.text_body =~ "Success!"
      assert email.html_body == nil
    end
  end

  test "export/1 err email", context do
    with_mock ExAws, request!: fn _a, _b -> throw("Intentional Error") end do
      {_job, email} = Exporter.export(context.export_job)

      assert email.from == {nil, "plenario@uchicago.edu"}
      assert email.to == [nil: context.user.email]
      assert email.subject == "Plenario Notification"
      assert email.text_body =~ "Intentional Error"
      assert email.html_body == nil
    end
  end

  test "export/1 sends success email", context do
    with_mock ExAws, request!: fn _a, _b -> :ok end do
      {_job, email} = Exporter.export(context.export_job)
      assert_delivered_email(email)
    end
  end

  test "export/1 sends error email", context do
    with_mock ExAws, request!: fn _a, _b -> throw("Intentional Error") end do
      {_job, email} = Exporter.export(context.export_job)
      assert_delivered_email(email)
    end
  end
end
