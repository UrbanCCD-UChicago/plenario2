defmodule Plenario.Testing.UserActionsTest do
  use Plenario.Testing.DataCase, async: true

  alias Plenario.Actions.UserActions

  test "new" do
    changeset = UserActions.new()

    assert changeset.action == nil
  end

  test "create", %{user: user} do
    assert user.is_active
    refute user.is_admin
  end

  describe "update" do
    test "name", %{user: user} do
      {:ok, _} = UserActions.update(user, [name: "new name"])
      user = UserActions.get(user.id)

      assert user.name == "new name"
    end

    test "email", %{user: user} do
      {:ok, _} = UserActions.update(user, [email: "new-email@example.com"])
      user = UserActions.get(user.id)

      assert user.email == "new-email@example.com"
    end

    test "bio", %{user: user} do
      {:ok, _} = UserActions.update(user, [bio: "i do stuff"])
      user = UserActions.get(user.id)

      assert user.bio == "i do stuff"
    end

    test "name, email and bio", %{user: user} do
      {:ok, _} = UserActions.update(user, [name: "new name", email: "new-email@example.com", bio: nil])
      user = UserActions.get(user.id)

      assert user.name == "new name"
      assert user.email == "new-email@example.com"
      assert user.bio == nil
    end

    test "with bad value for name", %{user: user} do
      {:error, _} = UserActions.update(user, [name: nil])
    end

    test "doesn't apply unknown key", %{user: user} do
      {:ok, _} = UserActions.update(user, dunno: "nope")
      user = UserActions.get(user.id)

      assert_raise KeyError, fn -> user.dunno end
    end
  end

  describe "change_password" do
    test "with a good value", %{user: user} do
      original_hash = user.password_hash

      {:ok, _} = UserActions.change_password(user, "new_password")
      user = UserActions.get(user.id)

      refute user.password_hash == original_hash
    end

    test "with a bad value", %{user: user} do
      {:error, _} = UserActions.change_password(user, "")
    end
  end

  test "archive", %{user: user} do
    {:ok, _} = UserActions.archive(user)
    user = UserActions.get(user.id)

    refute user.is_active
  end

  test "activate", %{user: user} do
    {:ok, _} = UserActions.archive(user)
    user = UserActions.get(user.id)

    {:ok, _} = UserActions.activate(user)
    user = UserActions.get(user.id)

    assert user.is_active
  end

  test "promote_to_admin", %{user: user} do
    {:ok, _} = UserActions.promote_to_admin(user)
    user = UserActions.get(user.id)

    assert user.is_admin
  end

  test "strip_admin_privs", %{user: user} do
    {:ok, _} = UserActions.promote_to_admin(user)
    user = UserActions.get(user.id)

    {:ok, _} = UserActions.strip_admin_privs(user)
    user = UserActions.get(user.id)

    refute user.is_admin
  end

  describe "get" do
    test "with an id", %{user: user} do
      assert UserActions.get(user.id)
    end

    test "with an email", %{user: user} do
      assert UserActions.get(user.email)
    end

    test "with a bad id" do
      nobody = UserActions.get(123456789)
      assert nobody == nil
    end

    test "with a bad email" do
      nobody = UserActions.get("noone@nowhere.com")
      assert nobody == nil
    end
  end

  describe "list" do
    test "vanilla" do
      users = UserActions.list()
      assert length(users) == 1
    end

    test "active_only" do
      users = UserActions.list(active_only: true)
      assert length(users) == 1
    end

    test "archived_only" do
      users = UserActions.list(archived_only: true)
      assert length(users) == 0
    end

    test "regular_only" do
      users = UserActions.list(regular_only: true)
      assert length(users) == 1
    end

    test "admins_only" do
      users = UserActions.list(admins_only: true)
      assert length(users) == 0
    end

    test "with_metas", %{meta: meta} do
      user =
        UserActions.list(with_metas: true)
        |> List.first()

      users_meta = List.first(user.metas)
      assert users_meta.id == meta.id
    end

    test "active admins only" do
      users = UserActions.list(active_only: true, admins_only: true)
      assert length(users) == 0
    end
  end
end
