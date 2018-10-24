defmodule Plenario.Testing.ChartActionsTest do
  use Plenario.Testing.DataCase

  alias Plenario.{
    ModelRegistry,
    Repo
  }

  alias Plenario.Actions.{
    ChartActions,
    DataSetActions,
    DataSetFieldActions,
    MetaActions,
    VirtualPointFieldActions
  }

  alias Plenario.Schemas.ChartDataset

  @fixture "test/fixtures/beach-lab-dna.csv"

  setup %{meta: meta} do
    # clear out the registry
    ModelRegistry.clear()

    # add fields
    {:ok, _} = DataSetFieldActions.create(meta, "DNA Test ID", "text")
    {:ok, ts} = DataSetFieldActions.create(meta, "DNA Sample Timestamp", "timestamp")
    {:ok, _} = DataSetFieldActions.create(meta, "Beach", "text")
    {:ok, s1} = DataSetFieldActions.create(meta, "DNA Sample 1 Reading", "float")
    {:ok, s2} = DataSetFieldActions.create(meta, "DNA Sample 2 Reading", "float")
    {:ok, sm} = DataSetFieldActions.create(meta, "DNA Reading Mean", "float")
    {:ok, _} = DataSetFieldActions.create(meta, "Culture Test ID", "text")
    {:ok, _} = DataSetFieldActions.create(meta, "Culture Sample 1 Timestamp", "text")
    {:ok, _} = DataSetFieldActions.create(meta, "Culture Sample 1 Reading", "text")
    {:ok, _} = DataSetFieldActions.create(meta, "Culture Sample 2 Reading", "text")
    {:ok, _} = DataSetFieldActions.create(meta, "Culture Reading Mean", "text")
    {:ok, _} = DataSetFieldActions.create(meta, "Culture Note", "text")
    {:ok, _} = DataSetFieldActions.create(meta, "Culture Sample Interval", "text")
    {:ok, _} = DataSetFieldActions.create(meta, "Culture Sample 2 Timestamp", "text")
    {:ok, lat} = DataSetFieldActions.create(meta, "Latitude", "float")
    {:ok, lon} = DataSetFieldActions.create(meta, "Longitude", "float")
    {:ok, loc} = DataSetFieldActions.create(meta, "Location", "text")
    {:ok, _} = VirtualPointFieldActions.create(meta, loc.id)
    {:ok, vpf} = VirtualPointFieldActions.create(meta, lat.id, lon.id)

    # get meta ready for ingest
    {:ok, meta} = MetaActions.submit_for_approval(meta)
    {:ok, meta} = MetaActions.approve(meta)

    # load data
    DataSetActions.etl!(meta.id, @fixture)

    # done
    {:ok, meta: meta, ts: ts, s1: s1, s2: s2, sm: sm, vpf: vpf}
  end

  test "new" do
    %Ecto.Changeset{action: nil, changes: %{}, data: data} =
      ChartActions.new()

    refute data.meta_id
    refute data.title
    refute data.type
    refute data.timestamp_field
    refute data.point_field
    refute data.group_by_field
  end

  test "create", %{meta: meta, ts: ts, vpf: vpf} do
    {:ok, _} = ChartActions.create(%{
      meta_id: meta.id,
      title: "whatever",
      type: "line",
      point_field: vpf.name,
      timestamp_field: ts.name,
      group_by_field: ts.name
    })
  end

  test "edit", %{meta: meta, ts: ts, vpf: vpf} do
    {:ok, chart} = ChartActions.create(%{
      meta_id: meta.id,
      title: "whatever",
      type: "line",
      point_field: vpf.name,
      timestamp_field: ts.name,
      group_by_field: ts.name
    })

    %Ecto.Changeset{action: nil, changes: %{}, data: data} =
      ChartActions.edit(chart.id)

    assert data.meta_id == chart.meta_id
    assert data.title == chart.title
    assert data.type == chart.type
    assert data.point_field == chart.point_field
    assert data.timestamp_field == chart.timestamp_field
    assert data.group_by_field == chart.group_by_field
  end

  test "update", %{meta: meta, ts: ts, vpf: vpf} do
    {:ok, chart} = ChartActions.create(%{
      meta_id: meta.id,
      title: "whatever",
      type: "line",
      point_field: vpf.name,
      timestamp_field: ts.name,
      group_by_field: ts.name
    })

    {:ok, updated} = ChartActions.update(chart.id, %{title: "something meaningful"})
    assert updated.title == "something meaningful"
    assert updated.meta_id == chart.meta_id
    assert updated.type == chart.type
    assert updated.point_field == chart.point_field
    assert updated.timestamp_field == chart.timestamp_field
    assert updated.group_by_field == chart.group_by_field
  end

  describe "get_agg_data without a group_by_field" do
    setup %{meta: meta, ts: ts, s1: s1, s2: s2, sm: sm, vpf: vpf} do
      {:ok, chart} = ChartActions.create(%{
        meta_id: meta.id,
        title: "whatever",
        type: "line",
        point_field: vpf.name,
        timestamp_field: ts.name
      })

      {:ok, _} =
        ChartDataset.changeset(%ChartDataset{}, %{
          chart_id: chart.id,
          label: "Sample 1",
          field_name: s1.name,
          func: "avg",
          color: "255,99,132",
          fill?: false
        })
        |> Repo.insert()
      {:ok, _} =
        ChartDataset.changeset(%ChartDataset{}, %{
          chart_id: chart.id,
          label: "Sample 2",
          field_name: s2.name,
          func: "avg",
          color: "54,162,235",
          fill?: false
        })
        |> Repo.insert()
      {:ok, _} =
        ChartDataset.changeset(%ChartDataset{}, %{
          chart_id: chart.id,
          label: "Sample Mean",
          field_name: sm.name,
          func: "avg",
          color: "153,102,255",
          fill?: true
        })
        |> Repo.insert()

      {:ok, chart: chart}
    end

    test "with bbox, time range, and granularity", %{chart: chart} do
      params = %{
        "starts" => "2017-07-01T00:00:00.0",
        "ends" => "2017-08-01T23:00:00.0",
        "granularity" => "week",
        "bbox" => Poison.encode!(%{
          "_northEast" => %{lat: 41.9, lng: -87.5},
          "_southWest" => %{lat: 41.7, lng: -87.7}
        })
      }

      %{labels: labels, datasets: datasets} =
        ChartActions.get_agg_data(chart.id, params)

      assert labels == [
        :"2017-06-26 00:00:00.000000", :"2017-07-03 00:00:00.000000",
        :"2017-07-10 00:00:00.000000", :"2017-07-17 00:00:00.000000",
        :"2017-07-24 00:00:00.000000", :"2017-07-31 00:00:00.000000"
      ]

      assert datasets == [
        %{
          data: [235.11111111111111, 928.936507936508, 1016.4354838709677, 2126.6833333333334, 839.758064516129, 206.83333333333334],
          label: "Sample 1"
        },
        %{
          data: [156.44444444444446, 808.1746031746031, 646.8166666666667, 1443.9833333333333, 1006.3333333333334, 390.3888888888889],
          label: "Sample 2"
        },
        %{
          data: [165.0277777777778, 832.8460317460317, 787.8306451612906, 1479.055, 819.5419354838708, 223.8444444444445],
          label: "Sample Mean"
        }
      ]
    end
  end
end
