defmodule PlenarioEtl.ExporterTest do
  use Plenario.Testing.EtlCase
  use Bamboo.Test

  alias PlenarioEtl.Exporter
  alias PlenarioEtl.Schemas.ExportJob

  import Ecto.Query
  import Mock

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
