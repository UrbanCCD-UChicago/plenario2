defmodule DataSetActionsTest do
  use ExUnit.Case, async: true
  alias Plenario2.Actions.{DataSetActions, DataSetFieldActions, DataSetConstraintActions, MetaActions, VirtualPointFieldActions, VirtualDateFieldActions}
  alias Plenario2.Schemas.Meta
  alias Plenario2.Repo
  alias Plenario2Auth.UserActions

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)

    {:ok, user} = UserActions.create("Test User", "password", "test@example.com")

    {:ok, meta} = MetaActions.create("Chicago Tree Trimming", user.id, "https://www.example.com/chicago-tree-trimming")

    DataSetFieldActions.create(meta.id, "event id", "text")
    DataSetFieldActions.create(meta.id, "long", "float")
    DataSetFieldActions.create(meta.id, "lat", "float")
    DataSetFieldActions.create(meta.id, "year", "integer")
    DataSetFieldActions.create(meta.id, "month", "integer")
    DataSetFieldActions.create(meta.id, "day", "integer")

    DataSetConstraintActions.create(meta.id, ["event_id"])

    VirtualPointFieldActions.create_from_long_lat(meta.id, "long", "lat")
    VirtualDateFieldActions.create(meta.id, "year", "month", "day")

    [meta: meta, table_name: Meta.get_data_set_table_name(meta)]
  end

  test "create a data set table", context do
    DataSetActions.create_data_set_table(context.meta)

    insert = """
    INSERT INTO #{context.table_name}
    VALUES
      ('abc123', 1.0, 1.0, 2017, 1, 1);
    """
    Ecto.Adapters.SQL.query(Repo, insert)

    query = """
    SELECT * FROM #{context.table_name}
    """
    {:ok, result} = Ecto.Adapters.SQL.query(Repo, query)
    assert result.rows == [["abc123", 1.0, 1.0, 2017, 1, 1, {{2017, 1, 1}, {0, 0, 0, 0}}, %Geo.Point{coordinates: {1.0, 1.0}, srid: 4326}]]
  end

  test "drop a data set table", context do
    DataSetActions.create_data_set_table(context.meta)
    DataSetActions.drop_data_set_table(context.meta)
  end
end
