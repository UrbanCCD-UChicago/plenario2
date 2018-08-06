defmodule PlenarioWeb.Api.DetailController do
  use PlenarioWeb, :api_controller

  import PlenarioWeb.Api.Plugs

  import PlenarioWeb.Api.Utils,
    only: [
      render_page: 5,
      map_to_query: 2,
      halt_with: 2,
      halt_with: 3
    ]

  alias Plenario.{
    ModelRegistry,
    Repo
  }

  alias Geo.Polygon

  alias Plenario.Actions.MetaActions

  alias Plenario.Schemas.Meta

  alias PlenarioWeb.Controllers.Api.CaptureArgs

  defmodule CaptureColumnArgs do
    def init(opts), do: opts

    def call(conn, opts) do
      meta = MetaActions.get(conn.params["slug"], with_virtual_points: true)
      do_call(meta, conn, opts)
    end

    def do_call(nil, conn, _opts) do
      conn |> halt_with(:not_found)
    end

    def do_call(%Meta{state: "ready"} = meta, conn, opts) do
      columns = MetaActions.get_column_names(meta)

      vpfs =
        meta.virtual_points()
        |> Enum.map(fn vpf -> vpf.name() end)

      CaptureArgs.call(conn, opts ++ [fields: columns ++ vpfs])
    end

    def do_call(_, conn, _), do: halt_with(conn, :not_found)
  end

  defmodule CaptureBboxArg do
    def init(opts), do: opts

    def call(%Plug.Conn{params: %{"bbox" => geojson}} = conn, opts),
      do: decode_param_to_map(geojson, conn, opts)

    def call(conn, opts), do: assign(conn, opts[:assign], [])

    defp decode_param_to_map(geojson, conn, opts),
      do: decode_map_to_polygon(Poison.decode!(geojson), conn, opts)

    defp decode_map_to_polygon(%{"type" => type, "coordinates" => _} = json, conn, opts)
         when type in ["Polygon", "polygon"] do
      # Fix Geo.JSON.decode particular nit pick about polygon needing
      # to start with an upper case. IMHO this is too strict.
      json = Map.merge(json, %{"type" => "Polygon"})
      assign_bbox(Geo.JSON.decode(json), conn, opts)
    end

    defp decode_map_to_polygon(_, conn, _), do: halt_with(conn, 400, "Cannot parse bbox value.")

    defp assign_bbox(%Polygon{} = poly, conn, opts) do
      poly = %Polygon{poly | srid: 4326}
      query = Map.to_list(%{"bbox" => {"in", poly}})
      assign(conn, opts[:assign], query)
    end

    defp assign_bbox(_, conn, _), do: halt_with(conn, 400, "Cannot parse bbox value.")
  end

  plug(CaptureArgs, assign: :ordering_fields, fields: ["order_by"])
  plug(CaptureArgs, assign: :windowing_fields, fields: ["row_id", "updated_at"])
  plug(:check_page)
  plug(:check_page_size, default_page_size: 500, page_size_limit: 5000)
  plug(CaptureColumnArgs, assign: :column_fields)
  plug(CaptureBboxArg, assign: :bbox_fields)

  def construct_query_from_conn_assigns(conn, %{"slug" => slug}) do
    case Regex.match?(~r/^\d+$/, slug) do
      true ->
        :error

      false ->
        do_construct_query_from_conn_assigns(slug, conn)
    end
  end

  defp do_construct_query_from_conn_assigns(slug, conn) do
    model =
      try do
        ModelRegistry.lookup(slug)
      rescue
        KeyError ->
          :error
      end

    make_query_params(model, conn)
  end

  defp make_query_params(:error, _), do: :error

  defp make_query_params(model, conn) do
    ordering_fields = Map.get(conn.assigns, :ordering_fields)
    windowing_fields = Map.get(conn.assigns, :windowing_fields)
    column_fields = Map.get(conn.assigns, :column_fields)
    bbox_query_map = Map.get(conn.assigns, :bbox_fields)

    query =
      model
      |> map_to_query(ordering_fields)
      |> map_to_query(windowing_fields)
      |> map_to_query(column_fields)
      |> map_to_query(bbox_query_map)

    params = windowing_fields ++ ordering_fields ++ column_fields ++ bbox_query_map

    {query, params}
  end

  def get(conn, params = %{"page" => page, "page_size" => page_size}) do
    pagination_fields = [page: page, page_size: page_size]

    case construct_query_from_conn_assigns(conn, params) do
      :error ->
        conn
        |> halt_with(:not_found)

      {query, params_used} ->
        page = Repo.paginate(query, pagination_fields)
        render_page(conn, "get.json", params_used ++ pagination_fields, page.entries, page)
    end
  end

  def head(conn, params = %{"page" => page}) do
    pagination_fields = [page: page, page_size: 1]

    case construct_query_from_conn_assigns(conn, params) do
      :error ->
        conn
        |> halt_with(:not_found)

      {query, params_used} ->
        page = Repo.paginate(query, pagination_fields)
        render_page(conn, "get.json", params_used ++ pagination_fields, page.entries, page)
    end
  end

  def describe(conn, params), do: get(conn, params)
end
