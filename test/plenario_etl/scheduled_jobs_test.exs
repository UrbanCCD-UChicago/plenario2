defmodule PlentioEtl.Testing.ScheduledJobsTest do
  use ExUnit.Case, async: true
  alias Plenario.Actions.{MetaActions, UserActions}
  alias Plenario.Repo
  alias PlenarioEtl.ScheduledJobs

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  end

  test "find refreshable metas" do
    {:ok, user} = UserActions.create("Test User", "test@example.com", "password")

    MetaActions.create("NoOp Data", user.id, "https://www.example.com/no-op", "csv")

    {:ok, meta} =
      MetaActions.create(
        "Chicago Tree Trimming",
        user.id,
        "https://www.example.com/chicago-tree-trimming",
        "csv"
      )

    {:ok, meta} =
      MetaActions.update(
        meta,
        refresh_starts_on: Timex.shift(DateTime.utc_now(), years: -1),
        refresh_ends_on: nil,
        refresh_rate: "minutes",
        refresh_interval: 1
      )

    MetaActions.update_next_import(meta)
    good_meta = meta

    {:ok, meta} =
      MetaActions.create("Some Old Dataset", user.id, "https://www.example.com/some-old-data-set", "csv")

    MetaActions.update(
      meta,
      refresh_starts_on: Timex.shift(DateTime.utc_now(), years: -2),
      refresh_ends_on: Timex.shift(DateTime.utc_now(), years: -1),
      refresh_rate: "minutes",
      refresh_interval: 1
    )

    metas = for m <- ScheduledJobs.find_refreshable_metas(), do: %{id: m.id, name: m.name}
    assert metas == [%{id: good_meta.id, name: good_meta.name}]
  end
end
