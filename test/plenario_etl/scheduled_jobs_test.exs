defmodule PlenarioEtl.Testing.ScheduledJobsTest do
  use ExUnit.Case 

  alias Plenario.Actions.{MetaActions, UserActions}

  alias PlenarioEtl.ScheduledJobs

  setup do
    # checkout a connection
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Plenario.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Plenario.Repo, {:shared, self()})

    # setup the user
    {:ok, user} = UserActions.create("Test User", "user@example.com", "password")

    # create some metas
    {:ok, meta1} = MetaActions.create("Meta 1", user, "https://example.com/1", "csv")
    {:ok, meta2} = MetaActions.create("Meta 2", user, "https://example.com/2", "csv")
    {:ok, meta3} = MetaActions.create("Meta 3", user, "https://example.com/3", "csv")
    {:ok, meta4} = MetaActions.create("Meta 4", user, "https://example.com/4", "csv")
    {:ok, meta5} = MetaActions.create("Meta 5", user, "https://example.com/5", "csv")

    # get the current datetime
    now = DateTime.utc_now()

    # meta1 started and ended in the past
    {:ok, meta1} = MetaActions.update(meta1,
      refresh_rate: "days",
      refresh_interval: 1,
      refresh_starts_on: Timex.shift(now, years: -3),
      refresh_ends_on: Timex.shift(now, years: -2),
      next_import: Timex.shift(now, years: -2)
    )
    {:ok, meta1} = MetaActions.submit_for_approval(meta1)
    {:ok, meta1} = MetaActions.approve(meta1)
    {:ok, meta1} = MetaActions.mark_first_import(meta1)

    # meta2 is not in a ready state
    {:ok, meta2} = MetaActions.update(meta2,
      refresh_rate: "days",
      refresh_interval: 1,
      refresh_starts_on: now
    )
    {:ok, meta2} = MetaActions.submit_for_approval(meta2)

    # meta3 starts in the future
    {:ok, meta3} = MetaActions.update(meta3,
      refresh_rate: "days",
      refresh_interval: 1,
      refresh_starts_on: Timex.shift(now, months: 1)
    )
    {:ok, meta3} = MetaActions.submit_for_approval(meta3)
    {:ok, meta3} = MetaActions.approve(meta3)

    # meta4 is currently being ingested
    {:ok, meta4} = MetaActions.update(meta4,
      refresh_rate: "days",
      refresh_interval: 1,
      refresh_starts_on: Timex.shift(now, years: -3),
      next_import: Timex.shift(%DateTime{now | second: 0, microsecond: {0, 0}}, seconds: -1)
    )
    {:ok, meta4} = MetaActions.submit_for_approval(meta4)
    {:ok, meta4} = MetaActions.approve(meta4)
    {:ok, meta4} = MetaActions.mark_first_import(meta4)

    # meta5 is awaiting first import
    {:ok, meta5} = MetaActions.update(meta5,
      refresh_rate: "days",
      refresh_interval: 1,
      refresh_starts_on: now
    )
    {:ok, meta5} = MetaActions.submit_for_approval(meta5)
    {:ok, meta5} = MetaActions.approve(meta5)

    # add to context
    {:ok, [
      user: user, meta1: meta1, meta2: meta2, meta3: meta3,
      meta4: meta4, meta5: meta5
    ]}
  end

  test "refresh_datasets", context do
    metas = for m <- ScheduledJobs.refresh_datasets(), do: m.id

    assert length(metas) == 2
    assert context.meta4.id in metas
    assert context.meta5.id in metas
  end
end
