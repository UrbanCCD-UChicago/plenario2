defmodule DataSetFieldTests do
  use ExUnit.Case, async: true
  alias Plenario2.Core.Actions.{DataSetFieldActions, MetaActions, UserActions}
  alias Plenario2.Repo

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  end

  test "create a data set field" do
    {:ok, user} = UserActions.create_user("Test User", "password", "test@example.com")
    {:ok, meta} = MetaActions.create("Chicago Tree Trimming", user.id, "https://www.example.com/chicago-tree-trimming")

    {:ok, field} = DataSetFieldActions.create(meta.id, "location", "text")
    assert field.opts == "default null"
  end

  test "name is downcased and _ joined" do
    {:ok, user} = UserActions.create_user("Test User", "password", "test@example.com")
    {:ok, meta} = MetaActions.create("Chicago Tree Trimming", user.id, "https://www.example.com/chicago-tree-trimming")

    {:ok, field} = DataSetFieldActions.create(meta.id, "EVENT ID", "text")
    assert field.name == "event_id"
  end

  test "list fields for meta" do
    {:ok, user} = UserActions.create_user("Test User", "password", "test@example.com")
    {:ok, meta} = MetaActions.create("Chicago Tree Trimming", user.id, "https://www.example.com/chicago-tree-trimming")

    DataSetFieldActions.create(meta.id, "location", "text")
    DataSetFieldActions.create(meta.id, "date", "timestamptz")

    fields = DataSetFieldActions.list_for_meta(meta)
    assert length(fields) == 2
  end

  test "make a data set field a primary key" do
    {:ok, user} = UserActions.create_user("Test User", "password", "test@example.com")
    {:ok, meta} = MetaActions.create("Chicago Tree Trimming", user.id, "https://www.example.com/chicago-tree-trimming")

    {:ok, field} = DataSetFieldActions.create(meta.id, "location", "text")
    {:ok, field} = DataSetFieldActions.make_primary_key(field)
    assert field.opts == "not null primary key"
  end

  test "delete a data set field" do
    {:ok, user} = UserActions.create_user("Test User", "password", "test@example.com")
    {:ok, meta} = MetaActions.create("Chicago Tree Trimming", user.id, "https://www.example.com/chicago-tree-trimming")

    {:ok, field} = DataSetFieldActions.create(meta.id, "location", "text")
    DataSetFieldActions.delete(field)

    assert length(DataSetFieldActions.list_for_meta(meta)) == 0
  end
end
