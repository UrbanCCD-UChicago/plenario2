defmodule PlenarioMailer.Testing.AdminUserNoteActionsTest do
  use Plenario.Testing.DataCase, async: true

  alias Plenario.Actions.UserActions

  alias PlenarioMailer.Actions.AdminUserNoteActions

  setup context do
    user = context[:user]
    {:ok, _} = UserActions.promote_to_admin(user)
    context
  end

  test "create for meta", %{user: user, meta: meta} do
    {:ok, _} = AdminUserNoteActions.create_for_meta(
      meta, user, user, "This is a test", false)
  end

  test "get", %{user: user, meta: meta} do
    {:ok, n} = AdminUserNoteActions.create_for_meta(
      meta, user, user, "This is a test", false)

    note = AdminUserNoteActions.get(n.id)
    assert note.meta_id == meta.id
    assert note.user_id == user.id
    assert note.admin_id == user.id
    refute note.acknowledged
  end

  test "mark acknowleged", %{user: user, meta: meta} do
    {:ok, n} = AdminUserNoteActions.create_for_meta(
      meta, user, user, "This is a test", false)

    {:ok, _} = AdminUserNoteActions.mark_acknowledged(n)

    note = AdminUserNoteActions.get(n.id)
    assert note.acknowledged
  end

  describe "list" do
    setup %{user: user, meta: meta} do
      {:ok, n} = AdminUserNoteActions.create_for_meta(
        meta, user, user, "This is a test", false)
      {:ok, [note: n]}
    end
    test "all" do
      all_notes = AdminUserNoteActions.list()
      assert length(all_notes) == 1
    end

    test "unread only" do
      unread = AdminUserNoteActions.list(unread_only: true)
      assert length(unread) == 1
    end

    test "acknowledged only" do
      read = AdminUserNoteActions.list(acknowledged_only: true)
      assert length(read) == 0
    end

    test "for user", %{user: user} do
      users_notes = AdminUserNoteActions.list(for_user: user)
      assert length(users_notes) == 1
    end

    test "for meta", %{meta: meta} do
      metas_notes = AdminUserNoteActions.list(for_meta: meta)
      assert length(metas_notes) == 1
    end
  end
end
