defmodule UserActionsTests do
  use ExUnit.Case
  alias Plenario2.Core.Actions.UserActions
  alias Plenario2.Repo

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  end

  test "create a user" do
    {:ok, user} = UserActions.create_user("Test User", "password", "test@example.com")
    assert user
    assert user.name == "Test User"
    assert user.email_address == "test@example.com"
    refute user.hashed_password == "password"
  end

  test "list users" do
    assert [] == UserActions.list_users()

    {:ok, _} = UserActions.create_user("Test User", "password", "test@example.com")
    assert length(UserActions.list_users()) == 1
  end

  test "get a user by primary key" do
    {:ok, user} = UserActions.create_user("Test User", "password", "test@example.com")

    found = UserActions.get_user_from_pk(user.id)
    assert user.email_address == found.email_address
  end

  test "archive and activate a user" do
    {:ok, user} = UserActions.create_user("Test User", "password", "test@example.com")
    assert user.is_active == true

    UserActions.archive_user(user)
    user = UserActions.get_user_from_pk(user.id)
    assert user.is_active == false

    UserActions.activate_archived_user(user)
    user = UserActions.get_user_from_pk(user.id)
    assert user.is_active == true
  end

  test "trust and untrust a user" do
    {:ok, user} = UserActions.create_user("Test User", "password", "test@example.com")
    assert user.is_trusted == false

    UserActions.trust_user(user)
    user = UserActions.get_user_from_pk(user.id)
    assert user.is_trusted == true

    UserActions.untrust_user(user)
    user = UserActions.get_user_from_pk(user.id)
    assert user.is_trusted == false
  end

  test "promote and revoke user to admin" do
    {:ok, user} = UserActions.create_user("Test User", "password", "test@example.com")
    assert user.is_admin == false

    UserActions.promote_to_admin(user)
    user = UserActions.get_user_from_pk(user.id)
    assert user.is_admin == true

    UserActions.revoke_admin(user)
    user = UserActions.get_user_from_pk(user.id)
    assert user.is_admin == false
  end

  test "change user name" do
    {:ok, user} = UserActions.create_user("Test User", "password", "test@example.com")

    UserActions.update_user_name(user, "Spiffy New Name")
    user = UserActions.get_user_from_pk(user.id)
    assert user.name == "Spiffy New Name"
  end

  test "change user password" do
    {:ok, user} = UserActions.create_user("Test User", "password", "test@example.com")
    original = user.hashed_password

    UserActions.update_user_password(user, "new password")
    user = UserActions.get_user_from_pk(user.id)
    new = user.hashed_password
    assert new != original
  end

  test "change user email address" do
    {:ok, user} = UserActions.create_user("Test User", "password", "test@example.com")

    UserActions.update_user_email_address(user, "test2@example.com")
    user = UserActions.get_user_from_pk(user.id)
    assert user.email_address == "test2@example.com"
  end

  test "change user organization info" do
    {:ok, user} = UserActions.create_user("Test User", "password", "test@example.com")

    UserActions.update_user_org_info(user, org: "Plenario")
    user = UserActions.get_user_from_pk(user.id)
    assert user.organization == "Plenario"

    UserActions.update_user_org_info(user, role: "Lead Engineer")
    user = UserActions.get_user_from_pk(user.id)
    assert user.org_role == "Lead Engineer"

    UserActions.update_user_org_info(user, org: nil, role: "Bum")
    user = UserActions.get_user_from_pk(user.id)
    assert user.organization == nil
    assert user.org_role == "Bum"
  end

  test "authenticate user" do
    {:error, message} = UserActions.authenticate("test@example.com", "password")
    assert message =~ "Email address or password is incorrect"

    {:ok, _} = UserActions.create_user("Test User", "password", "test@example.com")

    {:error, message} = UserActions.authenticate("test@example.com", "wrong password")
    assert message =~ "Email address or password is incorrect"

    {:ok, user} = UserActions.authenticate("test@example.com", "password")
    assert user.name == "Test User"
  end
end
