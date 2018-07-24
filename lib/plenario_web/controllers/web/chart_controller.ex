defmodule PlenarioWeb.Web.ChartController do
  use PlenarioWeb, :web_controller

  alias Plenario.Repo

  alias Plenario.Actions.{
    MetaActions,
    VirtualDateFieldActions,
    VirtualPointFieldActions,
    ChartActions
  }

  alias Plenario.Schemas.{Chart, ChartDataset}

  plug :put_layout, false when action in [:render_chart]

  def show(conn, %{"id" => chart_id}) do
    chart = ChartActions.get(chart_id)

    render conn, "show.html",
      chart: chart,
      meta: chart.meta
  end

  def new(conn, %{"meta_id" => meta_id}) do
    changeset = ChartActions.new()
    action = chart_path(conn, :create, meta_id)
    meta = MetaActions.get(meta_id, with_fields: true)

    render conn, "create.html",
      changeset: changeset,
      action: action,
      meta: meta,
      types: Chart.get_type_choices(),
      fields: get_fields(meta)
  end

  def create(conn, %{"meta_id" => meta_id, "chart" => chart_params}) do
    ChartActions.create(chart_params)
    |> do_create(conn, meta_id)
  end

  defp do_create({:ok, chart}, conn, meta_id) do
    conn
    |> put_flash(:success, "Created new chart #{inspect(chart.title)}")
    |> redirect(to: chart_path(conn, :show, meta_id, chart.id))
  end

  defp do_create({:error, changeset}, conn, meta_id) do
    action = chart_path(conn, :create, meta_id)
    meta = MetaActions.get(meta_id, with_fields: true)

    conn
    |> put_status(:bad_request)
    |> put_flash(:error, "Please correct errors in the form below.")
    |> render("create.html",
      changeset: changeset,
      action: action,
      meta: meta,
      types: Chart.get_type_choices(),
      fields: get_fields(meta)
    )
  end

  def edit(conn, %{"meta_id" => meta_id, "id" => chart_id}) do
    chart = ChartActions.get(chart_id)
    changeset = Chart.changeset(chart)
    action = chart_path(conn, :update, meta_id, chart_id)
    meta = MetaActions.get(meta_id, with_fields: true)

    render conn, "update.html",
      changeset: changeset,
      action: action,
      meta: meta,
      chart: chart,
      types: Chart.get_type_choices(),
      fields: get_fields(meta)
  end

  def update(conn, %{"meta_id" => meta_id, "id" => chart_id, "chart" => chart_params}) do
    chart = ChartActions.get(chart_id)
    changeset = Chart.changeset(chart, chart_params)
    do_update Repo.update(changeset), conn, meta_id, chart_id, chart
  end

  defp do_update({:ok, chart}, conn, meta_id, chart_id, _) do
    conn
    |> put_flash(:success, "Updated chart #{inspect(chart.title)}")
    |> redirect(to: chart_path(conn, :show, meta_id, chart_id))
  end

  defp do_update({:error, changeset}, conn, meta_id, chart_id, chart) do
    action = chart_path(conn, :update, meta_id, chart_id)
    meta = MetaActions.get(meta_id, with_fields: true)

    conn
    |> put_status(:bad_request)
    |> put_flash(:error, "Please correct error in the form below.")
    |> render("update.html",
      changeset: changeset,
      action: action,
      meta: meta,
      chart: chart,
      types: Chart.get_type_choices(),
      fields: get_fields(meta)
    )
  end

  def delete(conn, %{"meta_id" => meta_id, "id" => chart_id}) do
    chart = ChartActions.get(chart_id)
    Repo.delete!(chart)

    conn
    |> put_flash(:success, "Deleted chart #{inspect(chart.title)}")
    |> redirect(to: data_set_path(conn, :show, meta_id))
  end

  def render_chart(conn, %{"id" => chart_id} = params) do
    chart = ChartActions.get(chart_id)
    %{labels: labels, datasets: datasets} =
      ChartActions.get_agg_data(chart_id, params)

    do_render_chart chart, conn, labels, datasets
  end

  defp do_render_chart(chart, conn, labels, datasets) do
    datasets = apply_colors(chart.type, chart, datasets)

    json =
      Poison.encode!(%{
        type: chart.type,
        options: %{
          title: %{
            display: true,
            text: chart.title
          }
        },
        data: %{
          labels: labels,
          datasets: datasets
        }
      })

    render conn, "render_chart.html",
      chart_id: chart.id,
      chart_dump: json
  end

  defp apply_colors("line", chart, datasets) do
    ds =
      chart.datasets
      |> Enum.map(fn d -> {String.to_atom(d.label), {d.color, d.fill?}} end)

    datasets
    |> Enum.map(fn d ->
      {color, fill?} = Keyword.get(ds, String.to_atom(d.label))
      Map.merge(d, %{
        borderColor: "rgba(#{color},1)",
        backgroundColor: "rgba(#{color},0.2)",
        fill: fill?
      })
    end)
  end

  defp apply_colors(_, _, datasets) do
    borders =
      ChartDataset.get_colors()
      |> Enum.map(& "rgba(#{&1},1)")
      |> Stream.cycle()
    backgrounds =
      ChartDataset.get_colors()
      |> Enum.map(& "rgba(#{&1},0.2)")
      |> Stream.cycle()

    datasets
    |> Enum.map(fn d ->
      bord_colors = borders |> Enum.take(length(d.data))
      back_colors = backgrounds |> Enum.take(length(d.data))
      Map.merge(d, %{
        borderColor: bord_colors,
        backgroundColor: back_colors
      })
    end)
  end

  # helpers

  defp get_fields(meta) do
    dates = VirtualDateFieldActions.list(for_meta: meta.id, with_fields: true)
    points = VirtualPointFieldActions.list(for_meta: meta.id, with_fields: true)
    fields =
      Enum.map(meta.fields, & {&1.name, &1.name}) ++
      Enum.map(dates, & {VirtualDateFieldActions.make_pretty_name(&1), &1.name}) ++
      Enum.map(points, & {VirtualPointFieldActions.make_pretty_name(&1), &1.name})

    fields
  end
end
