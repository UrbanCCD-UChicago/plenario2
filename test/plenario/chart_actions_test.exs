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

    test "with empty params", %{chart: chart} do
      %{labels: labels, datasets: datasets} =
        ChartActions.get_agg_data(chart.id, %{})

      assert labels == [:"2015-06-08 00:00:00.000000", :"2015-08-10 00:00:00.000000", :"2016-08-15 00:00:00.000000", :"2017-07-24 00:00:00.000000", :"2017-07-31 00:00:00.000000", :"2017-06-19 00:00:00.000000", :"2015-06-01 00:00:00.000000", :"2016-07-11 00:00:00.000000", :"2017-05-22 00:00:00.000000", :"2016-08-29 00:00:00.000000", :"2016-08-01 00:00:00.000000", :"2016-05-23 00:00:00.000000", :"2016-06-06 00:00:00.000000", :"2015-08-24 00:00:00.000000", :"2017-05-29 00:00:00.000000", :"2016-08-08 00:00:00.000000", :"2017-08-28 00:00:00.000000", :"2015-08-03 00:00:00.000000", :"2015-07-20 00:00:00.000000", :"2015-06-29 00:00:00.000000", :"2016-06-20 00:00:00.000000", :"2017-06-12 00:00:00.000000", :"2017-08-14 00:00:00.000000", :"2017-09-04 00:00:00.000000", :"2015-06-22 00:00:00.000000", :"2017-06-26 00:00:00.000000", :"2017-07-10 00:00:00.000000", :"2017-08-07 00:00:00.000000", :"2016-07-18 00:00:00.000000", :"2016-07-04 00:00:00.000000", :"2016-06-13 00:00:00.000000", :"2015-07-06 00:00:00.000000", :"2017-07-03 00:00:00.000000", :"2015-07-13 00:00:00.000000", :"2015-06-15 00:00:00.000000", :"2017-07-17 00:00:00.000000", :"2016-05-30 00:00:00.000000", :"2015-08-17 00:00:00.000000", :"2015-07-27 00:00:00.000000", :"2016-06-27 00:00:00.000000", :"2016-07-25 00:00:00.000000", :"2017-06-05 00:00:00.000000", :"2016-08-22 00:00:00.000000", :"2017-08-21 00:00:00.000000", :"2015-05-25 00:00:00.000000"]

      assert datasets == [%{data: [1034.35, 340.55, 174.75434782608698, 841.6036496350363, 800.3007142857136, 528.2228571428574, 317.3, 245.88409090909093, 185.5471698113208, 186.54444444444445, 99.08297872340425, 122.3111111111111, 417.31777777777774, 157.55, 200.56857142857157, 110.52777777777777, 1030.6876811594202, 426.55, 149.3, 163.86666666666667, 231.95111111111115, 416.0921428571427, 582.3514285714284, 335.245, 471.25, 375.88873239436606, 791.7705035971218, 542.6021582733812, 323.09629629629626, 175.25111111111113, 108.09777777777776, 1004.55, 665.8621428571429, 190.9, 324.65, 1340.9117647058822, 311.16739130434775, 273.2857142857143, 240.95, 189.58444444444447, 373.2466666666666, 213.16569343065703, 298.58913043478276, 334.4879432624112, 269.73333333333335], label: "DNA Reading Mean"}, %{data: [822.4649999999998, 624.365, 202.52173913043478, 885.8029197080292, 789.5214285714286, 771.3214285714286, 499.61499999999995, 196.04545454545453, 210.16981132075472, 186.95555555555555, 105.04255319148936, 87.33333333333333, 539.2666666666667, 220.77000000000004, 211.18571428571428, 121.97222222222223, 1143.644927536232, 509.03500000000014, 164.63499999999996, 152.88, 292.3333333333333, 464.45, 561.0285714285715, 338.3, 526.32, 461.71830985915494, 1006.4892086330935, 600.1079136690647, 309.9259259259259, 232.0, 156.57777777777778, 867.7549999999998, 745.8571428571429, 208.73500000000004, 466.7299999999999, 1931.139705882353, 340.10869565217394, 328.40476190476187, 289.21999999999997, 228.24444444444444, 426.97777777777776, 295.0, 233.7608695652174, 399.6099290780142, 270.4933333333334], label: "DNA Sample 1 Reading"}, %{data: [2295.525, 272.4, 173.32608695652175, 986.4253731343283, 1091.355072463768, 579.25, 269.15, 606.8809523809524, 218.02, 200.9318181818182, 115.2127659574468, 411.6666666666667, 478.35555555555555, 181.76499999999996, 239.81428571428572, 119.75, 1136.0296296296297, 628.385, 180.54, 197.75999999999993, 230.0222222222222, 458.0863309352518, 1051.9352517985612, 394.3333333333333, 484.925, 437.34507042253523, 818.6691176470588, 542.1510791366907, 547.4629629629629, 240.75555555555556, 112.11111111111111, 2287.3599999999997, 678.3142857142857, 227.33499999999998, 276.6800000000001, 1425.6985294117646, 416.19565217391306, 406.147619047619, 263.035, 192.06666666666666, 387.1111111111111, 275.6296296296296, 428.54347826086956, 454.1714285714286, 353.96000000000004], label: "DNA Sample 2 Reading"}]
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
          data: [165.0277777777778, 832.8460317460317, 787.8306451612906, 1479.055, 819.5419354838708, 223.8444444444445],
          label: "DNA Reading Mean"
        },
        %{
          data: [235.11111111111111, 928.936507936508, 1016.4354838709677, 2126.6833333333334, 839.758064516129, 206.83333333333334],
          label: "DNA Sample 1 Reading"
        },
        %{
          data: [156.44444444444446, 808.1746031746031, 646.8166666666667, 1443.9833333333333, 1006.3333333333334, 390.3888888888889],
          label: "DNA Sample 2 Reading"
        }
      ]
    end
  end
end
