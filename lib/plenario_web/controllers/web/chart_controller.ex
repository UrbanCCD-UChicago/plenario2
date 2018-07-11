defmodule PlenarioWeb.Web.ChartController do
  use PlenarioWeb, :web_controller

  import Ecto.Query

  alias Plenario.{ModelRegistry, Repo}

  alias Plenario.Actions.{
    MetaActions,
    VirtualDateFieldActions,
    VirtualPointFieldActions
  }

  alias Plenario.Schemas.{Chart, ChartDataset, DataSetField}

  def show(conn, %{"meta_id" => meta_id, "id" => chart_id}) do
    chart =
      Repo.one!(
        from c in Chart,
        where: c.id == ^chart_id,
        preload: [datasets: :chart, meta: :charts]
      )

    render conn, "show.html",
      chart: chart,
      meta: chart.meta
  end

  def new(conn, %{"meta_id" => meta_id}) do
    changeset = Chart.changeset()
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
    changeset = Chart.changeset(%Chart{}, chart_params)
    do_create Repo.insert(changeset), conn, meta_id
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
    chart = Repo.get!(Chart, chart_id)
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
    chart = Repo.get!(Chart, chart_id)
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
    chart = Repo.get!(Chart, chart_id)
    Repo.delete!(chart)

    conn
    |> put_flash(:success, "Deleted chart #{inspect(chart.title)}")
    |> redirect(to: meta_path(conn, :show, meta_id))
  end

  def render_chart(conn, %{"id" => chart_id}) do
    chart =
      Repo.one!(
        from c in Chart,
        where: c.id == ^chart_id,
        preload: [datasets: :chart, meta: :charts]
      )

    do_render_chart chart, conn
  end

  # TODO: add in bbox and timerange filters

  defp do_render_chart(%Chart{type: type} = chart, conn) when type in ["location", "heatmap"] do
    conn
    |> put_status(500)
    |> render("500.html")
  end

  defp do_render_chart(chart, conn) do
    model = ModelRegistry.lookup(chart.meta.slug)

    group_by_func = get_group_by_func(chart.meta_id, chart.group_by_field)

    groups =
      select_groups(group_by_func, model, chart.group_by_field)
      |> Repo.all()
      |> Enum.map(& String.to_atom("#{&1}"))

    datasets =
      chart.datasets
      |> Enum.map(fn d ->
        data =
          select_dataset(group_by_func, model, chart.group_by_field, d)
          |> Repo.all()
          |> Enum.map(fn {k, v} -> {String.to_atom("#{k}"), v} end)

        selected_data =
          groups
          |> Enum.map(& Keyword.get(data, &1, 0))

        %{
          label: d.label,
          data: selected_data,
          borderColor: "rgba(#{d.color},1)",
          backgroundColor: "rgba(#{d.color},0.2)",
          fill: d.fill?
        }
      end)

    # make chart object
    dumpable =
      %{
        type: chart.type,
        options: %{title: %{display: true, text: chart.title}},
        data: %{
          labels: groups,
          datasets: datasets
        }
      }
      |> Poison.encode!()

    render conn, "render_chart.html",
      chart_id: chart.id,
      chart_dump: dumpable
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

  defp get_group_by_func(meta_id, field_name) do
    cond do
      String.starts_with?(field_name, "vdf") ->
        :date_trunc

      String.starts_with?(field_name, "vpf") ->
        :distict

      true ->
        %DataSetField{type: type} =
          Repo.one(
            from d in DataSetField,
            where: d.meta_id == ^meta_id and d.name == ^field_name)

        case type do
          "timestamp" ->
            :date_trunc

          _ ->
            :distinct
        end
    end
  end

  defp select_groups(:date_trunc, queryable, field_name) do
    queryable
    |> select([m], type(fragment("date_trunc('day', ?)", field(m, ^String.to_atom(field_name))), :naive_datetime))
    |> distinct(true)
    |> where([m], not is_nil(fragment("date_trunc('day', ?)", field(m, ^String.to_atom(field_name)))))
    |> order_by([m], fragment("date_trunc('day', ?)", field(m, ^String.to_atom(field_name))))
  end

  defp select_groups(:distinct, queryable, field_name) do
    queryable
    |> select([m], field(m, ^String.to_atom(field_name)))
    |> distinct(true)
    |> where([m], not is_nil(field(m, ^String.to_atom(field_name))))
    |> order_by([m], field(m, ^String.to_atom(field_name)))
  end

  defp select_dataset(:date_trunc, queryable, group_by_field, %ChartDataset{func: "count", field_name: field_name}) do
    queryable
    |> select([m], {
      type(fragment("date_trunc('day', ?)", field(m, ^String.to_atom(group_by_field))), :naive_datetime),
      count(field(m, ^String.to_atom(field_name)))
    })
    |> group_by([m], fragment("date_trunc('day', ?)", field(m, ^String.to_atom(group_by_field))))
    |> where([m], not is_nil(fragment("date_trunc('day', ?)", field(m, ^String.to_atom(group_by_field)))))
  end

  defp select_dataset(:distinct, queryable, group_by_field, %ChartDataset{func: "count", field_name: field_name}) do
    queryable
    |> select([m], {
      field(m, ^String.to_atom(group_by_field)),
      count(field(m, ^String.to_atom(field_name)))
    })
    |> group_by([m], field(m, ^String.to_atom(group_by_field)))
    |> where([m], not is_nil(field(m, ^String.to_atom(group_by_field))))
  end

  defp select_dataset(:date_trunc, queryable, group_by_field, %ChartDataset{func: "avg", field_name: field_name}) do
    queryable
    |> select([m], {
      type(fragment("date_trunc('day', ?)", field(m, ^String.to_atom(group_by_field))), :naive_datetime),
      avg(field(m, ^String.to_atom(field_name)))
    })
    |> group_by([m], fragment("date_trunc('day', ?)", field(m, ^String.to_atom(group_by_field))))
    |> where([m], not is_nil(fragment("date_trunc('day', ?)", field(m, ^String.to_atom(group_by_field)))))
  end

  defp select_dataset(:distinct, queryable, group_by_field, %ChartDataset{func: "avg", field_name: field_name}) do
    queryable
    |> select([m], {
      field(m, ^String.to_atom(group_by_field)),
      avg(field(m, ^String.to_atom(field_name)))
    })
    |> group_by([m], field(m, ^String.to_atom(group_by_field)))
    |> where([m], not is_nil(field(m, ^String.to_atom(group_by_field))))
  end

  defp select_dataset(:date_trunc, queryable, group_by_field, %ChartDataset{func: "min", field_name: field_name}) do
    queryable
    |> select([m], {
      type(fragment("date_trunc('day', ?)", field(m, ^String.to_atom(group_by_field))), :naive_datetime),
      min(field(m, ^String.to_atom(field_name)))
    })
    |> group_by([m], fragment("date_trunc('day', ?)", field(m, ^String.to_atom(group_by_field))))
    |> where([m], not is_nil(fragment("date_trunc('day', ?)", field(m, ^String.to_atom(group_by_field)))))
  end

  defp select_dataset(:distinct, queryable, group_by_field, %ChartDataset{func: "min", field_name: field_name}) do
    queryable
    |> select([m], {
      field(m, ^String.to_atom(group_by_field)),
      min(field(m, ^String.to_atom(field_name)))
    })
    |> group_by([m], field(m, ^String.to_atom(group_by_field)))
    |> where([m], not is_nil(field(m, ^String.to_atom(group_by_field))))
  end

  defp select_dataset(:date_trunc, queryable, group_by_field, %ChartDataset{func: "max", field_name: field_name}) do
    queryable
    |> select([m], {
      type(fragment("date_trunc('day', ?)", field(m, ^String.to_atom(group_by_field))), :naive_datetime),
      max(field(m, ^String.to_atom(field_name)))
    })
    |> group_by([m], fragment("date_trunc('day', ?)", field(m, ^String.to_atom(group_by_field))))
    |> where([m], not is_nil(fragment("date_trunc('day', ?)", field(m, ^String.to_atom(group_by_field)))))
  end

  defp select_dataset(:distinct, queryable, group_by_field, %ChartDataset{func: "max", field_name: field_name}) do
    queryable
    |> select([m], {
      field(m, ^String.to_atom(group_by_field)),
      max(field(m, ^String.to_atom(field_name)))
    })
    |> group_by([m], field(m, ^String.to_atom(group_by_field)))
    |> where([m], not is_nil(field(m, ^String.to_atom(group_by_field))))
  end
end
