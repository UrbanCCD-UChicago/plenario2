defmodule DataSetConstraintActionsTest do
  use ExUnit.Case, async: true
  alias Plenario2.Core.Actions.{DataSetFieldActions, DataSetConstraintActions, MetaActions, UserActions}
  alias Plenario2.Repo

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)

    {:ok, user} = UserActions.create("Test User", "password", "test@example.com")
    {:ok, meta} = MetaActions.create("Chicago Tree Trimming", user.id, "https://www.example.com/chicago-tree-trimming")
    DataSetFieldActions.create(meta.id, "date", "date")
    DataSetFieldActions.create(meta.id, "location", "text")
    DataSetFieldActions.create(meta.id, "event_id", "text")

    [meta: meta]
  end

  test "create a new constraint with one field", context do
    {:ok, cons} = DataSetConstraintActions.create(context.meta.id, ["event_id"])
    assert cons.constraint_name == "unique_constraint_chicago_tree_trimming_event_id"
  end

  test "create a new constraint with two fields", context do
    {:ok, cons} = DataSetConstraintActions.create(context.meta.id, ["date", "location"])
    assert cons.constraint_name == "unique_constraint_chicago_tree_trimming_date_location"
  end

  test "creating a constraint with a field that doesn't exist in the dataset fails", context do
    {:error, _} = DataSetConstraintActions.create(context.meta.id, ["some_other_id"])
  end

  test "list constraints for a meta", context do
    DataSetConstraintActions.create(context.meta.id, ["date", "location"])
    assert length(DataSetConstraintActions.list_for_meta(context.meta)) == 1
  end

  test "delete a constraint", context do
    {:ok, cons} = DataSetConstraintActions.create(context.meta.id, ["date", "location"])
    DataSetConstraintActions.delete(cons)
    assert length(DataSetConstraintActions.list_for_meta(context.meta)) == 0
  end
end
