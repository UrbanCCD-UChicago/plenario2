defmodule DataSetFieldTests do
  use Plenario2.DataCase, async: true

  alias Plenario2.Actions.{DataSetFieldActions, MetaActions}

  alias Plenario2Auth.UserActions

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

  test "delete a data set field", context do
    {:ok, field} = DataSetFieldActions.create(context.meta.id, "location", "text")
    DataSetFieldActions.delete(field)

    assert length(DataSetFieldActions.list_for_meta(context.meta)) == 0
  end

  describe "update the field" do
    test "when the meta hasn't been approved yet", context do
      {:ok, field} = DataSetFieldActions.create(context.meta, "event_id", "text")

      {:ok, field} = DataSetFieldActions.update(field, %{type: "integer"})
      assert field.type == "integer"
    end

    test "with a bad type", context do
      {:ok, field} = DataSetFieldActions.create(context.meta, "event_id", "text")

      {:error, error} = DataSetFieldActions.update(field, %{type: "barf"})
      assert error.errors == [type: {"Invalid type selection", []}]
    end

    test "when the meta has already been approved", context do
      {:ok, field} = DataSetFieldActions.create(context.meta, "event_id", "text")

      UserActions.promote_to_admin(context.user)
      user = UserActions.get_from_id(context.user.id)
      meta = MetaActions.get(context.meta.id, [with_user: true])

      MetaActions.submit_for_approval(meta)
      meta = MetaActions.get(meta.id, [with_user: true])
      MetaActions.approve(meta, user)
      meta = MetaActions.get(meta.id, [with_user: true])
      assert meta.state == "ready"

      {:error, error} = DataSetFieldActions.update(field, %{type: "integer"})
      assert error.errors == [name: {"Cannot alter any fields after the parent data set has been approved. If you need to update this field, please contact the administrators.", []}]
    end
  end
end
