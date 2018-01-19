defmodule MetaQueriesTests do
  use Plenario2.DataCase, async: true

  alias Plenario2.Repo
  alias Plenario2.Actions.MetaActions
  alias Plenario2.Queries.MetaQueries, as: Q
  alias Plenario2Auth.UserActions

  test "from_id/1", %{user: user} do
    {:ok, meta} = MetaActions.create("test", user.id, "https://example.com/")

    found = Q.from_id(meta.id) |> Repo.one()
    assert found.id == meta.id
  end

  test "from_slug/1", %{user: user} do
    {:ok, meta} = MetaActions.create("test", user.id, "https://example.com/")

    found = Q.from_slug(meta.slug) |> Repo.one()
    assert found.id == meta.id
  end

  test "list/0", %{user: user} do
    MetaActions.create("test", user.id, "https://example.com/")
    MetaActions.create("test 2", user.id, "https://example.com/2")

    metas = Q.list() |> Repo.all()
    assert length(metas) == 3
  end

  test "with_user/1", %{user: user} do
    {:ok, meta} = MetaActions.create("test", user.id, "https://example.com/")

    found =
      Q.from_slug(meta.slug)
      |> Q.with_user()
      |> Repo.one()

    assert found.user.id == user.id
  end

  test "with_data_set_fields/1", %{user: user} do
    {:ok, meta} = MetaActions.create("test", user.id, "https://example.com/")

    found =
      Q.from_slug(meta.slug)
      |> Q.with_data_set_fields()
      |> Repo.one()

    assert length(found.data_set_fields) == 0
  end

  test "with_data_set_constraints/1", %{user: user} do
    {:ok, meta} = MetaActions.create("test", user.id, "https://example.com/")

    found =
      Q.from_slug(meta.slug)
      |> Q.with_data_set_constraints()
      |> Repo.one()

    assert length(found.data_set_constraints) == 0
  end

  test "with_virtual_date_fields/1", %{user: user} do
    {:ok, meta} = MetaActions.create("test", user.id, "https://example.com/")

    found =
      Q.from_slug(meta.slug)
      |> Q.with_virtual_date_fields()
      |> Repo.one()

    assert length(found.virtual_date_fields) == 0
  end

  test "with_virtual_point_fields/1", %{user: user} do
    {:ok, meta} = MetaActions.create("test", user.id, "https://example.com/")

    found =
      Q.from_slug(meta.slug)
      |> Q.with_virtual_point_fields()
      |> Repo.one()

    assert length(found.virtual_point_fields) == 0
  end

  test "with_data_set_diffs/1", %{user: user} do
    {:ok, meta} = MetaActions.create("test", user.id, "https://example.com/")

    found =
      Q.from_slug(meta.slug)
      |> Q.with_data_set_diffs()
      |> Repo.one()

    assert length(found.data_set_diffs) == 0
  end

  test "for_user/2", %{user: user} do
    {:ok, user2} = UserActions.create("Test User", "password", "test2@example.com")

    MetaActions.create("test", user.id, "https://example.com/")
    MetaActions.create("test 2", user2.id, "https://example.com/2")

    found =
      Q.list()
      |> Q.for_user(user)
      |> Repo.all()

    assert length(found) == 2
  end
end
