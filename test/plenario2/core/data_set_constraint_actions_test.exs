defmodule DataSetConstraintActionsTest do
  use ExUnit.Case, async: true
  alias Plenario2.Core.Actions.{DataSetConstraintActions, MetaActions, UserActions}
  alias Plenario2.Repo

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)

    {:ok, user} = UserActions.create("Test User", "password", "test@example.com")
    {:ok, meta} = MetaActions.create("Chicago Tree Trimming", user.id, "https://www.example.com/chicago-tree-trimming")

    [meta: meta]
  end

  test "create a new constraint", context do
    {:ok, cons} = DataSetConstraintActions.create(context.meta.id, ["date", "location"])
    assert cons.constraint_name == "unique_constraint_chicago_tree_trimming_date_location"
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
