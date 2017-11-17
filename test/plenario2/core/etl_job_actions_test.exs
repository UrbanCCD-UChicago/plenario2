defmodule EtlJobActionsTests do
  use ExUnit.Case, async: true
  alias Plenario2.Core.Actions.{EtlJobActions, MetaActions, UserActions}
  alias Plenario2.Repo

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)

    {:ok, user} = UserActions.create("Test User", "password", "test@example.com")
    {:ok, meta} = MetaActions.create("Chicago Tree Trimming", user.id, "https://www.example.com/chicago-tree-trimming")

    [meta: meta]
  end

  test "create a new job", context do
    {:ok, job} = EtlJobActions.create(context.meta.id)
    assert job.state == "new"
  end

  test "get a job by id", context do
    {:ok, job} = EtlJobActions.create(context.meta.id)

    found = EtlJobActions.get_from_pk(job.id)
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
    EtlJobActions.mark_started(job)

    job = EtlJobActions.get_from_pk(job.id)
    assert job.state == "running"
    assert job.started_on != nil
  end

  test "mark a job as erred", context do
    {:ok, job} = EtlJobActions.create(context.meta.id)
    EtlJobActions.mark_started(job)
    EtlJobActions.mark_erred(job, "test")

    job = EtlJobActions.get_from_pk(job.id)
    assert job.state == "erred"
    assert job.completed_on != nil
    assert job.error_message == "test"
  end

  test "mark a job as completed", context do
    {:ok, job} = EtlJobActions.create(context.meta.id)
    EtlJobActions.mark_started(job)
    EtlJobActions.mark_completed(job)

    job = EtlJobActions.get_from_pk(job.id)
    assert job.state == "completed"
    assert job.completed_on != nil
  end
end
