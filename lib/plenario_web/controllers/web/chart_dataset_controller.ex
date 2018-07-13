defmodule PlenarioWeb.Web.ChartDatasetController do
  use PlenarioWeb, :web_controller

  alias Plenario.Repo

  alias Plenario.Actions.{
    MetaActions,
    VirtualDateFieldActions,
    VirtualPointFieldActions
  }

  alias Plenario.Schemas.{Chart, ChartDataset}

  def new(conn, %{"meta_id" => meta_id, "chart_id" => chart_id}) do
    changeset = ChartDataset.changeset()
    action = chart_dataset_path(conn, :create, meta_id, chart_id)
    chart = Repo.get!(Chart, chart_id)

    render conn, "create.html",
      changeset: changeset,
      action: action,
      chart: chart,
      meta_id: meta_id,
      fields: get_fields(meta_id),
      funcs: ChartDataset.get_func_choices(),
      colors: ChartDataset.get_color_choices()
  end

  def create(conn, %{"meta_id" => meta_id, "chart_id" => chart_id, "chart_dataset" => cds_params}) do
    changeset = ChartDataset.changeset(%ChartDataset{}, cds_params)
    do_create Repo.insert(changeset), conn, meta_id, chart_id
  end

  defp do_create({:ok, cds}, conn, meta_id, chart_id) do
    conn
    |> put_flash(:success, "Added new dataset #{inspect(cds.label)}")
    |> redirect(to: chart_path(conn, :show, meta_id, chart_id))
  end

  defp do_create({:error, changeset}, conn, meta_id, chart_id) do
    action = chart_dataset_path(conn, :create, meta_id, chart_id)
    chart = Repo.get!(Chart, chart_id)

    conn
    |> put_status(:bad_request)
    |> put_flash(:error, "Please correct errors in the form below.")
    |> render("create.html",
      changeset: changeset,
      action: action,
      chart: chart,
      meta_id: meta_id,
      fields: get_fields(meta_id),
      funcs: ChartDataset.get_func_choices(),
      colors: ChartDataset.get_color_choices()
    )
  end

  def edit(conn, %{"meta_id" => meta_id, "chart_id" => chart_id, "id" => cds_id}) do
    dataset = Repo.get!(ChartDataset, cds_id)
    changeset = ChartDataset.changeset(dataset)
    action = chart_dataset_path(conn, :update, meta_id, chart_id, cds_id)
    chart = Repo.get!(Chart, chart_id)

    render conn, "update.html",
      changeset: changeset,
      action: action,
      chart: chart,
      meta_id: meta_id,
      dataset: dataset,
      fields: get_fields(meta_id),
      funcs: ChartDataset.get_func_choices(),
      colors: ChartDataset.get_color_choices()
  end

  def update(conn, %{"meta_id" => meta_id, "chart_id" => chart_id, "id" => cds_id, "chart_dataset" => cds_params}) do
    dataset = Repo.get!(ChartDataset, cds_id)
    changeset = ChartDataset.changeset(dataset, cds_params)
    do_update Repo.update(changeset), conn, meta_id, chart_id, cds_id, dataset
  end

  defp do_update({:ok, cds}, conn, meta_id, chart_id, _, _) do
    conn
    |> put_flash(:success, "Updated dataset #{inspect(cds.label)}")
    |> redirect(to: chart_path(conn, :show, meta_id, chart_id))
  end

  defp do_update({:error, changeset}, conn, meta_id, chart_id, cds_id, dataset) do
    action = chart_dataset_path(conn, :update, meta_id, chart_id, cds_id)
    chart = Repo.get!(Chart, chart_id)

    conn
    |> put_status(:bad_request)
    |> put_flash(:error, "Please correct errors in form below.")
    |> render("update.html",
      changeset: changeset,
      action: action,
      chart: chart,
      meta_id: meta_id,
      dataset: dataset,
      fields: get_fields(meta_id),
      funcs: ChartDataset.get_func_choices(),
      colors: ChartDataset.get_color_choices()
    )
  end

  def delete(conn, %{"meta_id" => meta_id, "chart_id" => chart_id, "id" => cds_id}) do
    dataset = Repo.get!(ChartDataset, cds_id)
    Repo.delete!(dataset)

    conn
    |> put_flash(:success, "Deleted dataset #{inspect(dataset.label)}")
    |> redirect(to: chart_path(conn, :show, meta_id, chart_id))
  end

  # helpers

  defp get_fields(meta_id) do
    meta = MetaActions.get(meta_id, with_fields: true)
    dates = VirtualDateFieldActions.list(for_meta: meta.id, with_fields: true)
    points = VirtualPointFieldActions.list(for_meta: meta.id, with_fields: true)
    fields =
      Enum.map(meta.fields, & {&1.name, &1.name}) ++
      Enum.map(dates, & {VirtualDateFieldActions.make_pretty_name(&1), &1.name}) ++
      Enum.map(points, & {VirtualPointFieldActions.make_pretty_name(&1), &1.name})

    fields
  end
end
