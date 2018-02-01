defmodule DataSetConstraintActionsTest do
  use Plenario.DataCase, async: true

  alias Plenario.Actions.{DataSetFieldActions, DataSetConstraintActions, MetaActions}

  alias PlenarioAuth.UserActions

  setup context do
    meta = context[:meta]

    DataSetFieldActions.create(meta.id, "date", "timestamptz")
    DataSetFieldActions.create(meta.id, "location", "text")
    DataSetFieldActions.create(meta.id, "event_id", "text")

    context
  end

  test "create a new constraint with one field", context do
    {:ok, cons} = DataSetConstraintActions.create(context.meta.id, ["event_id"])
    assert cons.constraint_name == "unique_constraint_chicago_tree_trimming_event_id"
  end

  test "create a new constraint with two fields", context do
    {:ok, cons} = DataSetConstraintActions.create(context.meta.id, ["date", "location"])
    assert cons.constraint_name == "unique_constraint_chicago_tree_trimming_date_location"
  end

  test "creating a constraint with a field that doesn't exist in the data set fails", context do
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

  describe "update a constraint" do
    test "when the meta hasn't been approved yet", context do
      {:ok, cons} = DataSetConstraintActions.create(context.meta.id, ["date", "location"])

      {:ok, cons} = DataSetConstraintActions.update(cons, %{field_names: ["date"]})
      assert cons.field_names == ["date"]
      assert cons.constraint_name == "unique_constraint_chicago_tree_trimming_date"
    end

    test "with bad field names", context do
      {:ok, cons} = DataSetConstraintActions.create(context.meta.id, ["date", "location"])

      {:error, error} = DataSetConstraintActions.update(cons, %{field_names: ["nope"]})

      assert error.errors == [
               field_names: {"Field names must exist as registered fields of the data set", []}
             ]
    end

    test "when the meta has already been approved", context do
      {:ok, cons} = DataSetConstraintActions.create(context.meta.id, ["date", "location"])

      UserActions.promote_to_admin(context.user)
      user = UserActions.get_from_id(context.user.id)
      meta = MetaActions.get(context.meta.id, with_user: true)

      MetaActions.submit_for_approval(meta)
      meta = MetaActions.get(meta.id, with_user: true)
      MetaActions.approve(meta, user)
      meta = MetaActions.get(meta.id, with_user: true)
      assert meta.state == "ready"

      {:error, error} = DataSetConstraintActions.update(cons, %{field_names: ["date"]})

      assert error.errors == [
               field_names:
                 {"Cannot alter any fields after the parent data set has been approved. If you need to update this field, please contact the administrators.",
                  []}
             ]
    end
  end
end
