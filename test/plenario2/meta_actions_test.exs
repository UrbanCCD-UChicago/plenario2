defmodule MetaActionsTests do
  use ExUnit.Case, async: true
  alias Plenario2.Actions.MetaActions
  alias Plenario2.Repo
  alias Plenario2Auth.UserActions

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  end

  test "create a meta" do
    {:ok, user} = UserActions.create("Test User", "password", "test@example.com")
    {:ok, meta} = MetaActions.create("Chicago Tree Trimming", user.id, "https://www.example.com/chicago-tree-trimming")

    assert meta.slug != nil
  end

  test "list all metas" do
    {:ok, user} = UserActions.create("Test User", "password", "test@example.com")
    MetaActions.create("Chicago Tree Trimming", user.id, "https://www.example.com/chicago-tree-trimming")

    {:ok, user2} = UserActions.create("Test User", "password", "test2@example.com")
    MetaActions.create("Chicago Pothole Fills", user2.id, "https://www.example.com/chicago-pothole-fills")

    metas = MetaActions.list()
    assert metas != []
    assert length(metas) == 2
  end

  test "list metas for a single user" do
    {:ok, user} = UserActions.create("Test User", "password", "test@example.com")
    MetaActions.create("Chicago Tree Trimming", user.id, "https://www.example.com/chicago-tree-trimming")

    {:ok, user2} = UserActions.create("Test User", "password", "test2@example.com")
    MetaActions.create("Chicago Pothole Fills", user2.id, "https://www.example.com/chicago-pothole-fills")

    metas = MetaActions.list_for_user(user)
    assert length(metas) == 1
  end

  test "get a meta from a pk" do
    {:ok, user} = UserActions.create("Test User", "password", "test@example.com")
    {:ok, meta} = MetaActions.create("Chicago Tree Trimming", user.id, "https://www.example.com/chicago-tree-trimming")

    found = MetaActions.get_from_id(meta.id)
    assert found.slug == meta.slug
  end

  test "get a meta from a slug" do
    {:ok, user} = UserActions.create("Test User", "password", "test@example.com")
    {:ok, meta} = MetaActions.create("Chicago Tree Trimming", user.id, "https://www.example.com/chicago-tree-trimming")

    found = MetaActions.get_from_slug(meta.slug)
    assert found.id == meta.id
  end

  test "update name" do
    {:ok, user} = UserActions.create("Test User", "password", "test@example.com")
    {:ok, meta} = MetaActions.create("Chicago Tree Trimming", user.id, "https://www.example.com/chicago-tree-trimming")

    MetaActions.update_name(meta, "Chicago Tree Trimming - 2017")
    updated = MetaActions.get_from_id(meta.id)
    assert updated.name == "Chicago Tree Trimming - 2017"
  end

  test "update owner" do
    {:ok, user} = UserActions.create("Test User", "password", "test@example.com")
    {:ok, user2} = UserActions.create("Test User2", "password", "test2@example.com")
    {:ok, meta} = MetaActions.create("Chicago Tree Trimming", user.id, "https://www.example.com/chicago-tree-trimming")

    MetaActions.update_user(meta, user2)
    updated = MetaActions.get_from_id(meta.id)
    assert updated.user_id == user2.id
  end

  test "update source info" do
    {:ok, user} = UserActions.create("Test User", "password", "test@example.com")
    {:ok, meta} = MetaActions.create("Chicago Tree Trimming", user.id, "https://www.example.com/chicago-tree-trimming")

    MetaActions.update_source_info(meta, [source_url: "https://example.com/tree-trim.json", source_type: "json"])
    updated = MetaActions.get_from_id(meta.id)
    assert updated.source_url == "https://example.com/tree-trim.json"
    assert updated.source_type == "json"
  end

  test "update description info" do
    {:ok, user} = UserActions.create("Test User", "password", "test@example.com")
    {:ok, meta} = MetaActions.create("Chicago Tree Trimming", user.id, "https://www.example.com/chicago-tree-trimming")

    MetaActions.update_description_info(meta, [description: "blah blah blah", attribution: "City of Chicago"])
    updated = MetaActions.get_from_id(meta.id)
    assert updated.description == "blah blah blah"
    assert updated.attribution == "City of Chicago"
  end

  test "update refresh info" do
    {:ok, user} = UserActions.create("Test User", "password", "test@example.com")
    {:ok, meta} = MetaActions.create("Chicago Tree Trimming", user.id, "https://www.example.com/chicago-tree-trimming")

    changes = [
      refresh_rate: "days",
      refresh_interval: 1,
      refresh_starts_on: %{year: 2017, month: 11, day: 1, hour: 0, minute: 0},
      refresh_ends_on: %{year: 2017, month: 12, day: 1, hour: 23, minute: 59}
    ]
    MetaActions.update_refresh_info(meta, changes)
    updated = MetaActions.get_from_id(meta.id)
    assert updated.refresh_rate == "days"
    assert updated.refresh_interval == 1
    assert updated.refresh_starts_on != nil
    assert updated.refresh_ends_on != nil
  end

#  test "update bbox" do
#    {:ok, user} = UserActions.create("Test User", "password", "test@example.com")
#    {:ok, meta} = MetaActions.create("Chicago Tree Trimming", user.id, "https://www.example.com/chicago-tree-trimming")
#  end

#  test "update timerange" do
#    {:ok, user} = UserActions.create("Test User", "password", "test@example.com")
#    {:ok, meta} = MetaActions.create("Chicago Tree Trimming", user.id, "https://www.example.com/chicago-tree-trimming")
#  end

  test "update next refresh" do
    {:ok, user} = UserActions.create("Test User", "password", "test@example.com")

    {:ok, meta} = MetaActions.create("Chicago Tree Trimming", user.id, "https://www.example.com/chicago-tree-trimming")
    {:ok, meta} = MetaActions.update_refresh_info(meta, [
      refresh_starts_on: Timex.shift(DateTime.utc_now(), [years: -1]),
      refresh_ends_on: nil,
      refresh_rate: "minutes",
      refresh_interval: 1
    ])
    {:ok, meta} = MetaActions.update_next_refresh(meta)

    assert meta.next_refresh != nil

    original = meta.next_refresh

    {:ok, meta} = MetaActions.update_next_refresh(meta)
    assert meta.next_refresh != original
  end

  test "delete a meta" do
    {:ok, user} = UserActions.create("Test User", "password", "test@example.com")
    {:ok, meta} = MetaActions.create("Chicago Tree Trimming", user.id, "https://www.example.com/chicago-tree-trimming")

    MetaActions.delete(meta)
    found = MetaActions.get_from_id(meta.id)
    assert found == nil
  end

  test "bad refresh info" do
    {:ok, user} = UserActions.create("Test User", "password", "test@example.com")

    {:error, changeset} = MetaActions.create(
      "Chicago Tree Trimming", user.id, "https://www.example.com/chicago-tree-trimming",
      [refresh_rate: "fortnight", refresh_interval: 3]
    )
    assert changeset.errors == [refresh_rate: {"Invalid value `fortnight`", []}]

    {:error, changeset} = MetaActions.create(
      "Chicago Tree Trimming", user.id, "https://www.example.com/chicago-tree-trimming",
      [source_type: "application/html"]
    )
    assert changeset.errors == [source_type: {"Invalid type `application/html`", []}]

    starts = DateTime.utc_now()
    ends = Timex.shift(starts, months: -1)
    {:error, changeset} = MetaActions.create(
      "Chicago Tree Trimming", user.id, "https://www.example.com/chicago-tree-trimming",
      [refresh_starts_on: starts, refresh_ends_on: ends]
    )
    assert changeset.errors == [refresh_ends_on: {"Invalid: end date cannot precede start date", []}]
  end

  test "submit meta for for approval" do
    {:ok, user} = UserActions.create("Test User", "password", "test@example.com")
    {:ok, meta} = MetaActions.create("Chicago Tree Trimming", user.id, "https://www.example.com/chicago-tree-trimming")

    assert meta.state == "new"

    {:ok, meta} = MetaActions.submit_for_approval(meta)

    assert meta.state == "needs_approval"
  end

  test "approve meta" do
    {:ok, user} = UserActions.create("Test User", "password", "test@example.com")
    {:ok, meta} = MetaActions.create("Chicago Tree Trimming", user.id, "https://www.example.com/chicago-tree-trimming")
    {:ok, meta} = MetaActions.submit_for_approval(meta)

    {:ok, meta} = MetaActions.approve(meta)
    assert meta.state == "ready"
  end

  test "disapprove meta" do
    {:ok, user} = UserActions.create("Test User", "password", "test@example.com")
    {:ok, meta} = MetaActions.create("Chicago Tree Trimming", user.id, "https://www.example.com/chicago-tree-trimming")
    {:ok, meta} = MetaActions.submit_for_approval(meta)

    {:ok, meta} = MetaActions.disapprove(meta)
    assert meta.state == "new"
  end

  test "mark meta as erred" do
    {:ok, user} = UserActions.create("Test User", "password", "test@example.com")
    {:ok, meta} = MetaActions.create("Chicago Tree Trimming", user.id, "https://www.example.com/chicago-tree-trimming")
    {:ok, meta} = MetaActions.submit_for_approval(meta)
    {:ok, meta} = MetaActions.approve(meta)

    {:ok, meta} = MetaActions.mark_erred(meta)
    assert meta.state == "erred"
  end

  test "mark meta as fixed" do
    {:ok, user} = UserActions.create("Test User", "password", "test@example.com")
    {:ok, meta} = MetaActions.create("Chicago Tree Trimming", user.id, "https://www.example.com/chicago-tree-trimming")
    {:ok, meta} = MetaActions.submit_for_approval(meta)
    {:ok, meta} = MetaActions.approve(meta)
    {:ok, meta} = MetaActions.mark_erred(meta)

    {:ok, meta} = MetaActions.mark_fixed(meta)
    assert meta.state == "ready"
  end
end
