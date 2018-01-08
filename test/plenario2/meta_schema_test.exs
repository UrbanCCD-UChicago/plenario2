defmodule MetaSchemaTests do
  use Plenario2.DataCase, async: true

  alias Plenario2.Actions.MetaActions

  test "get data set table name", context do
    name = MetaActions.get_data_set_table_name(context.meta)
    assert name == "chicago_tree_trimming"
  end

  test "get data set table name with non-latin characters", context do
    {:ok, meta} = MetaActions.create("進撃の巨人", context.user.id, "https://www.example.com/attack-on-titan")

    name = MetaActions.get_data_set_table_name(meta)
    assert name == "進撃の巨人"
  end
end
