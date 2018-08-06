defmodule PlenarioWeb.Api.ListController do
  use PlenarioWeb, :api_controller

  import Ecto.Query

  import PlenarioWeb.Api.Plugs

  import PlenarioWeb.Api.Utils,
    only: [
      halt_with: 3,
      render_page: 5,
      map_to_query: 2
    ]

  alias Geo.Polygon

  alias Plenario.Repo

  alias Plenario.Schemas.Meta

  alias PlenarioWeb.Controllers.Api.CaptureArgs

  defmodule CaptureColumnArgs do
    def init(opts), do: opts

    def call(conn, opts) do
      # todo(heyzoos) hardcoded removal of bbox so that it doesn't clash
      # todo(heyzoos) there has to be a more elegant way of doing this
      columns =
        Map.keys(Meta.__struct__())
        |> Stream.map(&to_string/1)
        |> Enum.filter(&(&1 != "bbox"))

      CaptureArgs.call(conn, opts ++ [fields: columns])
    end
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
      query = Map.to_list(%{"bbox" => {"intersects", poly}})
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

  @associations [:fields, :virtual_dates, :virtual_points, :user]

  def construct_query_from_conn_assigns(conn) do
    ordering_fields = Map.get(conn.assigns, :ordering_fields)
    windowing_fields = Map.get(conn.assigns, :windowing_fields)
    column_fields = Map.get(conn.assigns, :column_fields)
    bbox_query_map = Map.get(conn.assigns, :bbox_fields)

    query =
      Meta
      |> where([m], m.state == "ready")
      |> map_to_query(ordering_fields)
      |> map_to_query(windowing_fields)
      |> map_to_query(column_fields)
      |> map_to_query(bbox_query_map)

    params = windowing_fields ++ ordering_fields ++ column_fields ++ bbox_query_map

    {query, params}
  end

  @doc """
  Lists all metadata objects satisfying the provided query.
  """
  def get(conn, %{"page" => page, "page_size" => page_size}) do
    pagination_fields = [page: page, page_size: page_size]
    {query, params_used} = construct_query_from_conn_assigns(conn)
    page = Repo.paginate(query, pagination_fields)
    render_page(conn, "get.json", params_used ++ pagination_fields, page.entries, page)
  end

  def head(conn, %{"page" => page, "page_size" => _}) do
    pagination_fields = [page: page, page_size: 1]
    {query, params_used} = construct_query_from_conn_assigns(conn)
    page = Repo.paginate(query, pagination_fields)
    render_page(conn, "get.json", params_used ++ pagination_fields, page.entries, page)
  end

  @doc """
  Lists all single metadata objects satisfying the provided query. The metadata
  objects have all associations preloaded.
  """
  def describe(conn, %{"page" => page, "page_size" => page_size}) do
    pagination_fields = [page: page, page_size: page_size]
    {query, params_used} = construct_query_from_conn_assigns(conn)
    page = Repo.paginate(preload(query, ^@associations), pagination_fields)
    render_page(conn, "get.json", params_used ++ pagination_fields, page.entries, page)
  end
end
