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
    VirtualDateActions,
    VirtualPointActions,
    Repo
  }

  alias Plug.Conn

  # list plugs

  plug :assign_if_exists, [param: "with_user", value_override: true] when action in [:list]
  plug :assign_if_exists, [param: "with_fields", value_override: true] when action in [:list]
  plug :assign_if_exists, [param: "with_virtual_dates", value_override: true] when action in [:list]
  plug :assign_if_exists, [param: "with_virtual_points", value_override: true] when action in [:list]
  plug :list_bbox when action in [:list]
  plug :list_time_range when action in [:list]
  plug :order, [default: "asc:name", fields: ~W(name refresh_starts_on refresh_ends_on first_import latest_import next_import)] when action in [:list]

  # detail plugs

  plug :detail_bbox when action in [:detail]
  plug :detail_time_range when action in [:detail]

  # universal plugs
  plug :paginate

  ##
  #   CONTROLLER ACTIONS

  @spec list(Conn.t(), any()) :: Conn.t()
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

  @spec detail(Conn.t(), map()) :: Conn.t()
  def detail(conn, %{"slug" => slug}) do
    DataSetActions.get!(slug)
    |> do_detail(conn)
  end

  @spec aggregate(Conn.t(), map()) :: Conn.t()
  def aggregate(conn, %{"slug" => slug} = params) do
    DataSetActions.get!(slug)
    |> do_aggregate(conn, params)
  end

  ##
  #   DETAIL HELPERS

  defp do_detail(%DataSet{state: "ready"} = ds, %Conn{assigns: assigns} = conn) do
    fields = FieldActions.list(for_data_set: ds)

    model = ViewModelRegistry.lookup(ds)
    query = from v in model

    query =
      case Map.get(assigns, :time_range) do
        nil ->
          query

        range ->
          ts_fields = fields |> Enum.filter(& &1.type == "timestamp")
          vdates = VirtualDateActions.list(for_data_set: ds)

          range = Plenario.TsRange.to_postgrex(range)

          (ts_fields ++ vdates)
          |> Enum.map(& String.to_atom(&1.col_name))
          |> Enum.reduce(query, fn fname, query ->
            from v in query, or_where: fragment("?::tsrange @> ?::timestamp", ^range, field(v, ^fname))
          end)
      end


    query =
      case Map.get(assigns, :bbox) do
        nil ->
          query

        geom ->
          geo_fields = fields |> Enum.filter(& &1.type == "geometry")
          vpoints = VirtualPointActions.list(for_data_set: ds)

          (geo_fields ++ vpoints)
          |> Enum.map(& String.to_atom(&1.col_name))
          |> Enum.reduce(query, fn fname, query ->
            from v in query, or_where: fragment("st_contains(?, ?)", ^geom, field(v, ^fname))
          end)
      end

    {page, size} = Map.get(assigns, :paginate)
    query =
      from v in query,
      limit: ^size,
      offset: ^size * (^page - 1)

    results = Repo.all(query)

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

  ##
  #   AGGREGATE HELPERS

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
