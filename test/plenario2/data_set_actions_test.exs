defmodule DataSetActionsTest do
  use Plenario2.DataCase, async: true

  alias Plenario2.Actions.{
    DataSetActions,
    DataSetFieldActions,
    DataSetConstraintActions,
    MetaActions,
    VirtualPointFieldActions,
    VirtualDateFieldActions}
  alias Plenario2.Repo

  setup context do
    meta = context[:meta]

    DataSetFieldActions.create(meta.id, "event id", "text")
    DataSetFieldActions.create(meta.id, "long", "float")
    DataSetFieldActions.create(meta.id, "lat", "float")
    DataSetFieldActions.create(meta.id, "year", "integer")
    DataSetFieldActions.create(meta.id, "month", "integer")
    DataSetFieldActions.create(meta.id, "day", "integer")

    DataSetConstraintActions.create(meta.id, ["event_id"])

    VirtualPointFieldActions.create_from_long_lat(meta.id, "long", "lat")
    VirtualDateFieldActions.create(meta.id, "year", "month", "day")

    [table_name: MetaActions.get_data_set_table_name(meta)]
  end

  test "create a data set table", context do
    DataSetActions.create_data_set_table!(context.meta)

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
    DataSetActions.create_data_set_table!(context.meta)
    DataSetActions.drop_data_set_table!(context.meta)
  end

  describe "with non-alnum characters" do
    test "create with a dash in the name", context do
      {:ok, meta} = MetaActions.update_name(context.meta, "chicago - data")
      DataSetActions.create_data_set_table!(meta)
    end

    test "create with non latin chars", context do
      {:ok, meta} = MetaActions.update_name(context.meta, "進撃の巨人")
      DataSetActions.create_data_set_table!(meta)
    end

    test "drop", context do
      {:ok, meta} = MetaActions.update_name(context.meta, "chicago - data")
      DataSetActions.create_data_set_table!(meta)
      DataSetActions.drop_data_set_table!(meta)
    end
  end

  test "with a funky field name", context do
    DataSetFieldActions.create(context.meta.id, "to-day", "integer")
    VirtualDateFieldActions.create(context.meta.id, "year", "month", "to-day")

    DataSetActions.create_data_set_table!(context.meta)

    insert = """
    INSERT INTO #{context.table_name}
    VALUES
      ('abc123', 1.0, 1.0, 2017, 1, 1, 1);
    """
    Ecto.Adapters.SQL.query(Repo, insert)

    query = """
    SELECT * FROM #{context.table_name}
    """
    {:ok, result} = Ecto.Adapters.SQL.query(Repo, query)
    assert result.rows == [["abc123", 1.0, 1.0, 2017, 1, 1, 1, {{2017, 1, 1}, {0, 0, 0, 0}}, {{2017, 1, 1}, {0, 0, 0, 0}}, %Geo.Point{coordinates: {1.0, 1.0}, srid: 4326}]]
  end
end
