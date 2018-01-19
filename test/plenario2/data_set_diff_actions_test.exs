defmodule DataSetDiffActionsTest do
  use Plenario2.DataCase, async: true

  alias Plenario2.Actions.{
    DataSetDiffActions,
    EtlJobActions,
    DataSetFieldActions,
    DataSetConstraintActions
  }

  setup context do
    meta = context[:meta]

    DataSetFieldActions.create(meta.id, "date", "date")
    DataSetFieldActions.create(meta.id, "location", "text")
    DataSetFieldActions.create(meta.id, "event_id", "text")
    {:ok, cons} = DataSetConstraintActions.create(meta.id, ["event_id"])
    {:ok, job} = EtlJobActions.create(meta.id)

    [cons: cons, job: job]
  end

  test "create a diff", context do
    {:ok, _} =
      DataSetDiffActions.create(
        context.meta.id,
        context.cons.id,
        context.job.id,
        "date",
        "2017-01-01T00:00:00+00:00",
        "2017-01-01T00:00:01+00:00",
        DateTime.utc_now(),
        %{event_id: "my-unique-id"}
      )
  end

  test "list diffs for a data set", context do
    {:ok, _} =
      DataSetDiffActions.create(
        context.meta.id,
        context.cons.id,
        context.job.id,
        "date",
        "2017-01-01T00:00:00+00:00",
        "2017-01-01T00:00:01+00:00",
        DateTime.utc_now(),
        %{event_id: "my-unique-id"}
      )

    assert length(DataSetDiffActions.list_for_meta(context.meta)) == 1
  end
end
