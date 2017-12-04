defmodule UserQueriesTests do
  use ExUnit.Case, async: true
  alias Plenario2.Repo
  alias Plenario2Auth.UserActions
  alias Plenario2Auth.UserQueries, as: Q

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  end

  test "get_by_id/1" do
    {:ok, user} = UserActions.create("test user", "password", "test@example.com")
    found = Q.get_by_id(user.id) |> Repo.one()

    assert user.email_address == found.email_address
  end

  test "get_by_email/1" do
    {:ok, user} = UserActions.create("test user", "password", "test@example.com")
    found = Q.get_by_email(user.email_address) |> Repo.one()

    assert user.id == found.id
  end

  test "list/0" do
    UserActions.create("test user", "password", "test1@example.com")
    UserActions.create("test user", "password", "test2@example.com")
    UserActions.create("test user", "password", "test3@example.com")
    users = Q.list() |> Repo.all()

    assert length(users) == 3
  end

  test "active/1" do
    UserActions.create("test user", "password", "test@example.com")
    users = Q.list() |> Q.active() |> Repo.all()

    assert length(users) == 1
  end

  test "archived/1" do
    UserActions.create("test user", "password", "test@example.com")
    users = Q.list() |> Q.archived() |> Repo.all()

    assert length(users) == 0
  end

  test "trusted/1" do
    UserActions.create("test user", "password", "test@example.com")
    users = Q.list() |> Q.trusted() |> Repo.all()

    assert length(users) == 0
  end

  test "admin/1" do
    UserActions.create("test user", "password", "test@example.com")
    users = Q.list() |> Q.admin() |> Repo.all()

    assert length(users) == 0
  end

  test "with_metas/1" do
    {:ok, user} = UserActions.create("test user", "password", "test@example.com")
    found = Q.get_by_id(user.id) |> Q.with_metas() |> Repo.one()

    assert length(found.metas) == 0
  end
end
