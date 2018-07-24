defmodule PlenarioWeb.Testing.ChartControllerTest do
  use PlenarioWeb.Testing.ConnCase

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

  setup %{reg_user: user} do
    # clear out the registry
    ModelRegistry.clear()

    # create the meta
    {:ok, meta} = MetaActions.create("Beach Lab DNA", user, "http://example.com/", "csv")

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

    # create a chart
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

    # done
    {:ok, meta: meta, chart: chart, vpf: vpf, ts: ts}
  end

  @tag :auth
  test "new", %{conn: conn, meta: meta} do
    conn
    |> get(chart_path(conn, :new, meta.id))
    |> html_response(:ok)
  end

  @tag :auth
  test "create", %{conn: conn, meta: meta, vpf: vpf, ts: ts} do
    params = %{
      "chart" => %{
        "meta_id" => meta.id,
        "title" => "Sample Readings",
        "type" => "line",
        "point_field" => vpf.name,
        "timestamp_field" => ts.name,
        "group_by_field" => ts.name
      }
    }

    conn
    |> post(chart_path(conn, :create, meta.id, params))
    |> html_response(:found)
  end

  @tag :auth
  test "edit", %{conn: conn, meta: meta, chart: chart} do
    conn
    |> get(chart_path(conn, :edit, meta.id, chart.id))
    |> html_response(:ok)
  end

  @tag :auth
  test "update", %{conn: conn, meta: meta, chart: chart, vpf: vpf, ts: ts} do
    params = %{
      "chart" => %{
        "meta_id" => meta.id,
        "title" => "Sample Readings",
        "type" => "line",
        "point_field" => vpf.name,
        "timestamp_field" => ts.name,
        "group_by_field" => ts.name
      }
    }

    conn
    |> put(chart_path(conn, :update, meta.id, chart.id, params))
    |> html_response(:found)
  end

  describe "render_chart" do
    @tag :auth
    test "with empty params", %{conn: conn, meta: meta, chart: chart} do
      response =
        conn
        |> get(chart_path(conn, :render_chart, meta.id, chart.id))
        |> html_response(:ok)

      assert response =~ "canvas"
      assert response =~ "script"
      assert response =~ "new Chart"
      assert response =~ chart.title
      assert response =~ "datasets"

      chart = ChartActions.get(chart.id)
      chart.datasets
      |> Enum.map(fn d ->
        assert response =~ d.label
        assert response =~ d.color
      end)
    end
  end
end
