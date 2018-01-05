defmodule MetaActionsTests do
  use Plenario2.DataCase, async: true

  alias Plenario2.Actions.MetaActions

  alias Plenario2Auth.UserActions

  test "list all metas" do
    {:ok, user2} = UserActions.create("Test User", "password", "test2@example.com")
    MetaActions.create("Chicago Pothole Fills", user2.id, "https://www.example.com/chicago-pothole-fills")

    metas = MetaActions.list()
    assert metas != []
    assert length(metas) == 2
  end

  test "list metas for a single user", context do
    {:ok, user2} = UserActions.create("Test User", "password", "test2@example.com")
    MetaActions.create("Chicago Pothole Fills", user2.id, "https://www.example.com/chicago-pothole-fills")

    metas = MetaActions.list_for_user(context.user)
    assert length(metas) == 1
  end

  test "get a meta from a id", context do
    found = MetaActions.get(context.meta.id)
    assert found.slug == context.meta.slug
  end

  test "get a meta from a slug", context do
    found = MetaActions.get(context.meta.slug)
    assert found.id == context.meta.id
  end

  test "update name", context do
    MetaActions.update_name(context.meta, "Chicago Tree Trimming - 2017")
    updated = MetaActions.get(context.meta.id)
    assert updated.name == "Chicago Tree Trimming - 2017"
  end

  test "update owner", context do
    {:ok, user2} = UserActions.create("Test User2", "password", "test2@example.com")

    MetaActions.update_user(context.meta, user2)
    updated = MetaActions.get(context.meta.id)
    assert updated.user_id == user2.id
  end

  test "update source info", context do
    MetaActions.update_source_info(context.meta, [source_url: "https://example.com/tree-trim.json", source_type: "json"])
    updated = MetaActions.get(context.meta.id)
    assert updated.source_url == "https://example.com/tree-trim.json"
    assert updated.source_type == "json"
  end

  test "update description info", context do
    MetaActions.update_description_info(context.meta, [description: "blah blah blah", attribution: "City of Chicago"])
    updated = MetaActions.get(context.meta.id)
    assert updated.description == "blah blah blah"
    assert updated.attribution == "City of Chicago"
  end

  test "update refresh info", context do
    changes = [
      refresh_rate: "days",
      refresh_interval: 1,
      refresh_starts_on: %{year: 2017, month: 11, day: 1, hour: 0, minute: 0},
      refresh_ends_on: %{year: 2017, month: 12, day: 1, hour: 23, minute: 59}
    ]
    MetaActions.update_refresh_info(context.meta, changes)
    updated = MetaActions.get(context.meta.id)
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

  test "update next refresh", context do
    {:ok, meta} = MetaActions.update_refresh_info(context.meta, [
      refresh_starts_on: Timex.shift(DateTime.utc_now(), [years: -1]),
      refresh_ends_on: nil,
      refresh_rate: "minutes",
      refresh_interval: 1
    ])
    {:ok, meta} = MetaActions.update_next_refresh(meta)

    assert meta.next_refresh != nil

    original = context.meta.next_refresh

    {:ok, meta} = MetaActions.update_next_refresh(meta)
    assert meta.next_refresh != original
  end

  test "delete a meta", context do
    MetaActions.delete(context.meta)
    found = MetaActions.get(context.meta.id)
    assert found == nil
  end

  test "bad refresh info", context do
    {:error, changeset} = MetaActions.create(
      "Chicago Tree Trimming", context.user.id, "https://www.example.com/chicago-tree-trimming",
      [refresh_rate: "fortnight", refresh_interval: 3]
    )
    assert changeset.errors == [refresh_rate: {"Invalid value `fortnight`", []}]

    {:error, changeset} = MetaActions.create(
      "Chicago Tree Trimming", context.user.id, "https://www.example.com/chicago-tree-trimming",
      [source_type: "application/html"]
    )
    assert changeset.errors == [source_type: {"Invalid type `application/html`", []}]

    starts = DateTime.utc_now()
    ends = Timex.shift(starts, months: -1)
    {:error, changeset} = MetaActions.create(
      "Chicago Tree Trimming", context.user.id, "https://www.example.com/chicago-tree-trimming",
      [refresh_starts_on: starts, refresh_ends_on: ends]
    )
    assert changeset.errors == [refresh_ends_on: {"Invalid: end date cannot precede start date", []}]
  end

  test "submit meta for for approval", context do
    assert context.meta.state == "new"

    {:ok, meta} = MetaActions.submit_for_approval(context.meta)

    assert meta.state == "needs_approval"
  end

  describe "approve meta" do
    test "with admin", context do
      UserActions.promote_to_admin(context.user)
      {:ok, meta} = MetaActions.submit_for_approval(context.meta)

      user = UserActions.get_from_id(context.user.id)
      meta = MetaActions.get(meta.id, [with_user: true])
      {:ok, meta} = MetaActions.approve(meta, user)
      assert meta.state == "ready"
    end

    test "with regular user", context do
      {:ok, meta} = MetaActions.submit_for_approval(context.meta)

      user = UserActions.get_from_id(context.user.id)
      meta = MetaActions.get(meta.id, [with_user: true])

      {:error, error} = MetaActions.approve(meta, user)
      assert error =~ "not an admin"
    end
  end

  describe "disapprove meta" do
    test "with admin", context do
      UserActions.promote_to_admin(context.user)
      {:ok, meta} = MetaActions.submit_for_approval(context.meta)

      user = UserActions.get_from_id(context.user.id)
      meta = MetaActions.get(meta.id, [with_user: true])
      {:ok, meta} = MetaActions.disapprove(meta, user, "bad stuff")
      assert meta.state == "new"
    end

    test "with regular user", context do
      {:ok, meta} = MetaActions.submit_for_approval(context.meta)

      meta = MetaActions.get(meta.id, [with_user: true])
      {:error, error} = MetaActions.disapprove(meta, context.user, "bad stuff")
      assert error =~ "not an admin"
    end
  end

  describe "mark meta as erred" do
    test "with admin", context do
      UserActions.promote_to_admin(context.user)

      user = UserActions.get_from_id(context.user.id)
      meta = MetaActions.get(context.meta.id, [with_user: true])
      {:ok, meta} = MetaActions.submit_for_approval(meta)
      meta = MetaActions.get(meta.id, [with_user: true])
      {:ok, meta} = MetaActions.approve(meta, user)

      {:ok, meta} = MetaActions.mark_erred(meta, user, "something bad happened on our end")
      assert meta.state == "erred"
    end

    test "with regular user", context do
      UserActions.promote_to_admin(context.user)

      user = UserActions.get_from_id(context.user.id)
      meta = MetaActions.get(context.meta.id, [with_user: true])
      {:ok, meta} = MetaActions.submit_for_approval(meta)
      meta = MetaActions.get(meta.id, [with_user: true])
      {:ok, meta} = MetaActions.approve(meta, user)

      user = UserActions.get_from_id(user.id)
      UserActions.strip_admin(user)
      user = UserActions.get_from_id(user.id)

      {:error, error} = MetaActions.mark_erred(meta, user, "something bad happened on our end")
      assert error =~ "not an admin"
    end
  end

  describe "mark meta as fixed" do
    test "with admin", context do
      UserActions.promote_to_admin(context.user)

      user = UserActions.get_from_id(context.user.id)
      meta = MetaActions.get(context.meta.id, [with_user: true])
      {:ok, meta} = MetaActions.submit_for_approval(meta)
      meta = MetaActions.get(meta.id, [with_user: true])
      {:ok, meta} = MetaActions.approve(meta, user)
      meta = MetaActions.get(meta.id, [with_user: true])
      {:ok, meta} = MetaActions.mark_erred(meta, user, "something bad happened")
      meta = MetaActions.get(meta.id, [with_user: true])

      {:ok, meta} = MetaActions.mark_fixed(meta, user, "something good happened")
      assert meta.state == "ready"
    end

    test "with regular user", context do
      UserActions.promote_to_admin(context.user)

      user = UserActions.get_from_id(context.user.id)
      meta = MetaActions.get(context.meta.id, [with_user: true])
      {:ok, meta} = MetaActions.submit_for_approval(meta)
      meta = MetaActions.get(meta.id, [with_user: true])
      {:ok, meta} = MetaActions.approve(meta, user)
      meta = MetaActions.get(meta.id, [with_user: true])
      {:ok, meta} = MetaActions.mark_erred(meta, user, "something bad happened")
      meta = MetaActions.get(meta.id, [with_user: true])

      user = UserActions.get_from_id(user.id)
      UserActions.strip_admin(user)
      user = UserActions.get_from_id(user.id)

      {:error, error} = MetaActions.mark_fixed(meta, user, "something good happened")
      assert error =~ "not an admin"
    end
  end
end
