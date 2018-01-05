defmodule DataSetFieldTests do
  use Plenario2.DataCase, async: true

  alias Plenario2.Actions.DataSetFieldActions

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
