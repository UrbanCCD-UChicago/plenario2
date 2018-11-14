defmodule PlenarioWeb.DataSetApiController do
  use PlenarioWeb, :controller

  import Ecto.Query

  import PlenarioWeb.{
    ApiControllerUtils,
    ApiPlugs,
    DataSetApiPlugs
  }

  alias Plenario.{
    DataSet,
    DataSetActions,
    FieldActions,
    ViewModelRegistry,
    VirtualPointActions,
    Repo
  }

  plug :assign_if_exists, param: "with_user", value_override: true
  plug :assign_if_exists, param: "with_fields", value_override: true
  plug :assign_if_exists, param: "with_virtual_dates", value_override: true
  plug :assign_if_exists, param: "with_virtual_points", value_override: true
  plug :bbox
  plug :time_range
  plug :order, default: "asc:name", fields: ~W(name refresh_starts_on refresh_ends_on first_import latest_import next_import)
  plug :paginate

  def list(conn, _) do
    opts =
      conn.assigns
      |> Enum.into([])
      |> Keyword.merge([state: "ready"])
    data_sets = DataSetActions.list(opts)

    fmt = resp_format(conn)

    render conn, "list.json",
      data_sets: data_sets,
      response_format: fmt,
      metadata: meta(&Routes.data_set_api_url/3, :list, conn)
  end

  def detail(conn, %{"slug" => slug}) do
    DataSetActions.get!(slug)
    |> do_detail(conn)
  end

  defp do_detail(%DataSet{state: "ready"} = ds, conn) do
    model = ViewModelRegistry.lookup(ds)
    results = Repo.all(from m in model, limit: 1000)

    resp_format(conn)
    |> render_detail(conn, results, ds)
  end

  defp do_detail(_, conn), do: halt_with(conn, :not_found)

  defp render_detail("json", conn, results, ds) do
    render conn, "detail.json",
      results: results,
      metadata: meta(&Routes.data_set_api_url/4, :detail, conn, ds)
  end

  defp render_detail("geojson", conn, results, ds) do
    fields =
      FieldActions.list(for_data_set: ds)
      |> Enum.filter(& &1.type == "geometry")

    points = VirtualPointActions.list(for_data_set: ds)

    field =
      (fields ++ points)
      |> List.first()

    render conn, "detail.geojson",
      results: results,
      metadata: meta(&Routes.data_set_api_url/4, :detail, conn, ds),
      geojson_field: field
  end

  def aggregate(conn, %{"slug" => slug} = params) do
    DataSetActions.get!(slug)
    |> do_aggregate(conn, params)
  end

  defp do_aggregate(%DataSet{state: "ready"} = ds, conn, params) do
    model = ViewModelRegistry.lookup(ds)

    interval = Map.get(params, "granularity", "week")
    fieldname =
      Map.get(params, "group_by", ":created_at")
      |> String.to_atom()

    query =
      from m in model,
      select: {
        count(field(m, :":id")),
        fragment("date_trunc(?, ?) as interval", ^interval, field(m, ^fieldname))
      },
      group_by: fragment("interval"),
      order_by: fragment("interval")

    render conn, "aggregate.json",
      data: Repo.all(query)
  end

  defp do_aggregate(_, conn, _), do: halt_with(conn, :not_found)
end
