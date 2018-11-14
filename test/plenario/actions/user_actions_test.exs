defmodule Plenario.Testing.UserActionsTest do
  use Plenario.Testing.DataCase

  alias Plenario.UserActions

  describe "list" do
    @tag :user
    test "all users" do
      users = UserActions.list()
      assert length(users) == 1
    end

    @tag user: [is_admin?: true]
    test "only admins" do
      admins = UserActions.list(assert_is_admin: true)
      assert length(admins) == 1
    end

    @tag :user
    test "preload data sets" do
      UserActions.list()
      |> Enum.each(& refute Ecto.assoc_loaded?(&1.data_sets))

      UserActions.list(with_data_sets: true)
      |> Enum.each(& assert Ecto.assoc_loaded?(&1.data_sets))
    end
  end

  describe "get" do
    @tag :user
    test "with a known id", %{user: user} do
      {:ok, _} = UserActions.get(user.id)
    end

    @tag :user
    test "with a known email", %{user: user} do
      {:ok, _} = UserActions.get(user.email)
    end

    @tag :user
    test "with an unknown id" do
      {:error, nil} = UserActions.get(1234567899)
    end

    @tag :user
    test "with an unknown email" do
      {:error, nil} = UserActions.get("123456789@example.com")
    end
  end

  describe "get!" do
    @tag :user
    test "with a known id", %{user: user} do
      UserActions.get!(user.id)
    end

    @tag :user
    test "with a known email", %{user: user} do
      UserActions.get!(user.email)
    end

    @tag :user
    test "with an unknown id" do
      assert_raise Ecto.NoResultsError, fn ->
        UserActions.get!(123456789)
      end
    end

    @tag :user
    test "with an unknown email" do
      assert_raise Ecto.NoResultsError, fn ->
        UserActions.get!("123456789@example.com")
      end
    end
  end

  describe "create" do
    @tag :user
    test "with a taken email", %{user: user} do
      {:error, changeset} = UserActions.create username: "Another Users",
        email: user.email,
        password: "password"

      assert "has already been taken" in errors_on(changeset).email
    end

    test "with a malformed email" do
      {:error, changeset} = UserActions.create username: "Another User",
        email: "example.com",
        password: "password"

      assert "has invalid format" in errors_on(changeset).email
    end
  end

  describe "update" do
    @tag :user
    test "change password", %{user: user} do
      {:ok, updated} = UserActions.update(user, password: "_new_password_")
      refute updated.password_hash == user.password_hash
    end

    @tag :user
    test "change email to a taken email", %{user: user} do
      {:ok, other} = UserActions.create username: "Another User",
        email: "another@example.com",
        password: "password"

      {:error, changeset} = UserActions.update(other, email: user.email)
      assert "has already been taken" in errors_on(changeset).email
    end
  end

  describe "delete" do
    @tag :user
    test "when user has data sets", %{user: user} do
      _ = create_data_set(%{user: user})

      {:error, changeset} = UserActions.delete(user)
      assert "are still associated with this entry" in errors_on(changeset).data_sets
    end

    @tag :user
    test "when user doesn't have data sets", %{user: user} do
      {:ok, _} = UserActions.delete(user)
    end
  end

  describe "authenticate" do
    setup do
      email = "test@example.com"
      password = "password"

      _ = create_user(email: email, password: password)

      {:ok, email: email, password: password}
    end

    test "with a good email and password", %{email: email, password: password} do
      {:ok, _} = UserActions.authenticate(email, password)
    end

    test "with a bad email", %{password: password} do
      {:error, _} = UserActions.authenticate("dunno@nowhere.com", password)
    end

    test "with a bad password", %{email: email} do
      {:error, _} = UserActions.authenticate(email, "******")
    end
  end
end
