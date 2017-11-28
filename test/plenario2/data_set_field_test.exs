defmodule DataSetFieldTests do
  use ExUnit.Case, async: true
  alias Plenario2.Actions.{DataSetFieldActions, MetaActions}
  alias Plenario2.Repo
  alias Plenario2Auth.UserActions

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)

    {:ok, user} = UserActions.create("Test User", "password", "test@example.com")
    {:ok, meta} = MetaActions.create("Chicago Tree Trimming", user.id, "https://www.example.com/chicago-tree-trimming")

    [meta: meta]
  end

  test "create a data set field", context do
    {:ok, field} = DataSetFieldActions.create(context.meta.id, "location", "text")
    assert field.opts == "default null"
  end

  test "name is downcased and _ joined", context do
    {:ok, field} = DataSetFieldActions.create(context.meta.id, "EVENT ID", "text")
    assert field.name == "event_id"
  end

  test "list fields for meta", context do
    DataSetFieldActions.create(context.meta.id, "location", "text")
    DataSetFieldActions.create(context.meta.id, "date", "timestamptz")

    fields = DataSetFieldActions.list_for_meta(context.meta)
    assert length(fields) == 2
  end

  test "make a data set field a primary key", context do
    {:ok, field} = DataSetFieldActions.create(context.meta.id, "location", "text")
    {:ok, field} = DataSetFieldActions.make_primary_key(field)
    assert field.opts == "not null primary key"
  end

  test "delete a data set field", context do
    {:ok, field} = DataSetFieldActions.create(context.meta.id, "location", "text")
    DataSetFieldActions.delete(field)

    assert length(DataSetFieldActions.list_for_meta(context.meta)) == 0
  end
end
