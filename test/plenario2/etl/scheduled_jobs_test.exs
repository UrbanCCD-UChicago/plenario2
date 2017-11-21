defmodule ScheduledJobsTest do
  use ExUnit.Case, async: true
  alias Plenario2.Core.Actions.{MetaActions, UserActions}
  alias Plenario2.Etl.ScheduledJobs
  alias Plenario2.Repo

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  end

  test "find refreshable metas" do
    {:ok, user} = UserActions.create("Test User", "password", "test@example.com")

    MetaActions.create("NoOp Data", user.id, "https://www.example.com/no-op")

    {:ok, meta} = MetaActions.create("Chicago Tree Trimming", user.id, "https://www.example.com/chicago-tree-trimming")
    {:ok, meta} = MetaActions.update_refresh_info(meta, [
      refresh_starts_on: Timex.shift(DateTime.utc_now(), [years: -1]),
      refresh_ends_on: nil,
      refresh_rate: "minutes",
      refresh_interval: 1
    ])
    MetaActions.update_next_refresh(meta)
    good_meta = meta

    {:ok, meta} = MetaActions.create("Some Old Dataset", user.id, "https://www.example.com/some-old-dataset")
    MetaActions.update_refresh_info(meta, [
      refresh_starts_on: Timex.shift(DateTime.utc_now(), [years: -2]),
      refresh_ends_on: Timex.shift(DateTime.utc_now(), [years: -1]),
      refresh_rate: "minutes",
      refresh_interval: 1
    ])

    metas = for m <- ScheduledJobs.find_refreshable_metas(), do: %{id: m.id, name: m.name}
    assert metas == [%{id: good_meta.id, name: good_meta.name}]
  end
end
