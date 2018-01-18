defmodule EtlJobActionsTests do
  use Plenario2.DataCase, async: true

  alias Plenario2.Actions.EtlJobActions

  test "create a new job", context do
    {:ok, job} = EtlJobActions.create(context.meta.id)
    assert job.state == "new"
  end

  test "get a job by id", context do
    {:ok, job} = EtlJobActions.create(context.meta.id)

    found = EtlJobActions.get(job.id)
    assert found.id == job.id
  end

  test "list all jobs", context do
    EtlJobActions.create(context.meta.id)
    assert length(EtlJobActions.list()) == 1
  end

  test "list jobs for a meta", context do
    assert length(EtlJobActions.list_for_meta(context.meta)) == 0

    EtlJobActions.create(context.meta.id)

    assert length(EtlJobActions.list_for_meta(context.meta)) == 1
  end

  test "mark a job as started", context do
    {:ok, job} = EtlJobActions.create(context.meta.id)
    {:ok, job} = EtlJobActions.mark_started(job)

    assert job.state == "started"
    assert job.started_on != nil
  end

  test "mark a job as erred", context do
    {:ok, job} = EtlJobActions.create(context.meta.id)
    {:ok, job} = EtlJobActions.mark_started(job)
    {:ok, job} = EtlJobActions.mark_erred(job, %{error_message: "test"})

    assert job.state == "erred"
    assert job.completed_on != nil
    assert job.error_message == "test"
  end

  test "mark a job as completed", context do
    {:ok, job} = EtlJobActions.create(context.meta.id)
    {:ok, job} = EtlJobActions.mark_started(job)
    {:ok, job} = EtlJobActions.mark_completed(job)

    assert job.state == "completed"
    assert job.completed_on != nil
  end
end
