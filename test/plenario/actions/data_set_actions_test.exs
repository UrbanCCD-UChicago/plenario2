defmodule Plenario.Actions.DataSetActionsTest do
  use Plenario.Testing.DataCase 

  alias Plenario.Repo

  alias Plenario.Actions.{
    DataSetActions,
    DataSetFieldActions,
    VirtualDateFieldActions,
    VirtualPointFieldActions,
    UniqueConstraintActions
  }

  setup %{meta: meta} do
    {:ok, pk} = DataSetFieldActions.create(meta, "id", "integer")
    {:ok, _} = DataSetFieldActions.create(meta, "observation", "float")
    {:ok, yr} = DataSetFieldActions.create(meta, "year", "integer")
    {:ok, mo} = DataSetFieldActions.create(meta, "month", "integer")
    {:ok, day} = DataSetFieldActions.create(meta, "day", "integer")
    {:ok, lat} = DataSetFieldActions.create(meta, "lat", "float")
    {:ok, lon} = DataSetFieldActions.create(meta, "lon", "float")
    {:ok, loc} = DataSetFieldActions.create(meta, "loc", "text")

    {:ok, vdf} = VirtualDateFieldActions.create(meta.id, yr.id, month_field_id: mo.id, day_field_id: day.id)

    {:ok, vpf} = VirtualPointFieldActions.create(meta.id, lat.id, lon.id)
    {:ok, vpf2} = VirtualPointFieldActions.create(meta.id, loc.id)

    {:ok, uc} = UniqueConstraintActions.create(meta.id, [pk.id])

    {
      :ok,
      [
        pk: pk,
        yr: yr,
        mo: mo,
        day: day,
        lat: lat,
        lon: lon,
        vdf: vdf,
        vpf: vpf,
        vpf2: vpf2,
        uc: uc
      ]
    }
  end

  test "up!", %{meta: meta} do
    DataSetActions.up!(meta)

    insert = """
    INSERT INTO "#{meta.table_name}" VALUES
      (1, 12.3, 2018, 1, 1, 10.1, 20.9, '(10.1, 20.9)'),
      (2, 12.2, 2018, 1, 1, 10.1, 20.8, '(10.1, 20.8)'),
      (3, 12.1, 2018, 1, 1, 10.1, 20.7, '(10.1, 20.7)');
    """
    {:ok, _} = Ecto.Adapters.SQL.query(Repo, insert)

    query = """
    SELECT * FROM "#{meta.table_name}"
    """
    {:ok, result} = Ecto.Adapters.SQL.query(Repo, query)

    assert length(result.rows) == 3
    first = List.first(result.rows)
    assert first == [
      1, 12.3, 2018, 1, 1, 10.1, 20.9, "(10.1, 20.9)",
      {{2018, 1, 1}, {0, 0, 0, 0}}, # virtual date
      %Geo.Point{coordinates: {20.9, 10.1}, srid: 4326},  # virtual point
      %Geo.Point{coordinates: {20.9, 10.1}, srid: 4326}
    ]

    # check unique key
    insert = """
    INSERT INTO "#{meta.table_name}" VALUES
      (1, 12.4, 2018, 1, 1, 10.1, 20.9, '(10.1, 20.9)');
    """
    {:error, _} = Ecto.Adapters.SQL.query(Repo, insert)
  end

  test "down!", %{meta: meta} do
    DataSetActions.up!(meta)
    DataSetActions.down!(meta)
  end
end
