defmodule PlenarioWeb.Api.DetailController do
  @moduledoc """
  """

  use PlenarioWeb, :api_controller

  import Ecto.Query

  import Geo.PostGIS,
    only: [
      st_intersects: 2,
      st_within: 2
    ]

  import Plenario.Queries.Utils,
    only: [
      timestamp_within: 2,
      tsrange_intersects: 2
    ]

  import PlenarioWeb.Api.Plugs

  import PlenarioWeb.Api.Utils,
    only: [
      halt_with: 2,
      halt_with: 3
    ]

  alias Geo.Polygon

  alias Plenario.{
    ModelRegistry,
    Repo,
    TsRange
  }

  alias Plenario.Actions.MetaActions

  alias Plenario.Schemas.Meta

  plug(:check_page_size)
  plug(:check_page)
  plug(:check_order_by)
  plug(:check_filters)

  @spec get(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def get(conn, %{"slug" => slug}) do
    validate_data_set(slug)
    |> get_data_set(conn)
  end

  defp get_data_set(%Meta{state: "ready"} = meta, conn) do
    model = ModelRegistry.lookup(meta.slug)

    {dir, fname} = conn.assigns[:order_by]

    query =
      model
      |> order_by([q], [{^dir, ^fname}])

    query =
      conn.assigns[:filters]
      |> Enum.reduce(query, fn {fname, op, value}, query ->
        apply_filter(query, fname, op, value)
      end)

    try do
      page = conn.assigns[:page]
      page_size = conn.assigns[:page_size]
      data = Repo.paginate(query, page: page, page_size: page_size)
      render(conn, "get.json", data)
    rescue
      e in [Ecto.QueryError, Ecto.SubQueryError, Postgrex.Error] ->
        halt_with(conn, :bad_request, e.message)
    end
  end

  defp get_data_set(_, conn), do: halt_with(conn, :not_found)

  # helpers

  defp validate_data_set(slug) when is_bitstring(slug) do
    case Regex.match?(~r/^\d+$/, slug) do
      true ->
        nil

      false ->
        MetaActions.get(slug)
    end
  end

  defp validate_data_set(_), do: :error

  defp apply_filter(query, fname, "lt", value), do: where(query, [q], field(q, ^fname) < ^value)

  defp apply_filter(query, fname, "le", value), do: where(query, [q], field(q, ^fname) <= ^value)

  defp apply_filter(query, fname, "eq", value), do: where(query, [q], field(q, ^fname) == ^value)

  defp apply_filter(query, fname, "ge", value), do: where(query, [q], field(q, ^fname) >= ^value)

  defp apply_filter(query, fname, "gt", value), do: where(query, [q], field(q, ^fname) > ^value)

  defp apply_filter(query, fname, "within", %TsRange{} = value),
    do: where(query, [q], timestamp_within(field(q, ^fname), ^TsRange.to_postgrex(value)))

  defp apply_filter(query, fname, "within", %Polygon{} = value),
    do: where(query, [q], st_within(field(q, ^fname), ^value))

  defp apply_filter(query, fname, "intersects", %TsRange{} = value),
    do: where(query, [q], tsrange_intersects(field(q, ^fname), ^TsRange.to_postgrex(value)))

  defp apply_filter(query, fname, "intersects", %Polygon{} = value),
    do: where(query, [q], st_intersects(field(q, ^fname), ^value))
end

# defmodule PlenarioWeb.Api.DetailController do
#   use PlenarioWeb, :api_controller

#   import PlenarioWeb.Api.Plugs

#   import PlenarioWeb.Api.Utils,
#     only: [
#       render_page: 5,
#       map_to_query: 2,
#       halt_with: 2,
#       halt_with: 3
#     ]

#   alias Plenario.{
#     ModelRegistry,
#     Repo
#   }

#   alias Geo.Polygon

#   alias Plenario.Actions.MetaActions

#   alias Plenario.Schemas.Meta

#   alias PlenarioWeb.Controllers.Api.CaptureArgs

#   defmodule CaptureColumnArgs do
#     def init(opts), do: opts

#     def call(conn, opts) do
#       meta = MetaActions.get(conn.params["slug"], with_virtual_points: true)
#       do_call(meta, conn, opts)
#     end

#     def do_call(nil, conn, _opts) do
#       conn |> halt_with(:not_found)
#     end

#     def do_call(%Meta{state: "ready"} = meta, conn, opts) do
#       columns = MetaActions.get_column_names(meta)

#       vpfs =
#         meta.virtual_points()
#         |> Enum.map(fn vpf -> vpf.name() end)

#       CaptureArgs.call(conn, opts ++ [fields: columns ++ vpfs])
#     end

#     def do_call(_, conn, _), do: halt_with(conn, :not_found)
#   end

#   defmodule CaptureBboxArg do
#     def init(opts), do: opts

#     def call(%Plug.Conn{params: %{"bbox" => geojson}} = conn, opts),
#       do: decode_param_to_map(geojson, conn, opts)

#     def call(conn, opts), do: assign(conn, opts[:assign], [])

#     defp decode_param_to_map(geojson, conn, opts),
#       do: decode_map_to_polygon(Poison.decode!(geojson), conn, opts)

#     defp decode_map_to_polygon(%{"type" => type, "coordinates" => _} = json, conn, opts)
#          when type in ["Polygon", "polygon"] do
#       # Fix Geo.JSON.decode particular nit pick about polygon needing
#       # to start with an upper case. IMHO this is too strict.
#       json = Map.merge(json, %{"type" => "Polygon"})
#       assign_bbox(Geo.JSON.decode(json), conn, opts)
#     end

#     defp decode_map_to_polygon(_, conn, _), do: halt_with(conn, 400, "Cannot parse bbox value.")

#     defp assign_bbox(%Polygon{} = poly, conn, opts) do
#       poly = %Polygon{poly | srid: 4326}
#       query = Map.to_list(%{"bbox" => {"in", poly}})
#       assign(conn, opts[:assign], query)
#     end

#     defp assign_bbox(_, conn, _), do: halt_with(conn, 400, "Cannot parse bbox value.")
#   end

#   plug(CaptureArgs, assign: :ordering_fields, fields: ["order_by"])
#   plug(CaptureArgs, assign: :windowing_fields, fields: ["row_id", "updated_at"])
#   plug(:check_page)
#   plug(:check_page_size, default_page_size: 500, page_size_limit: 5000)
#   plug(CaptureColumnArgs, assign: :column_fields)
#   plug(CaptureBboxArg, assign: :bbox_fields)

#   def construct_query_from_conn_assigns(conn, %{"slug" => slug}) do
#     case Regex.match?(~r/^\d+$/, slug) do
#       true ->
#         :error

#       false ->
#         do_construct_query_from_conn_assigns(slug, conn)
#     end
#   end

#   defp do_construct_query_from_conn_assigns(slug, conn) do
#     model =
#       try do
#         ModelRegistry.lookup(slug)
#       rescue
#         KeyError ->
#           :error
#       end

#     make_query_params(model, conn)
#   end

#   defp make_query_params(:error, _), do: :error

#   defp make_query_params(model, conn) do
#     ordering_fields = Map.get(conn.assigns, :ordering_fields)
#     windowing_fields = Map.get(conn.assigns, :windowing_fields)
#     column_fields = Map.get(conn.assigns, :column_fields)
#     bbox_query_map = Map.get(conn.assigns, :bbox_fields)

#     query =
#       model
#       |> map_to_query(ordering_fields)
#       |> map_to_query(windowing_fields)
#       |> map_to_query(column_fields)
#       |> map_to_query(bbox_query_map)

#     params = windowing_fields ++ ordering_fields ++ column_fields ++ bbox_query_map

#     {query, params}
#   end

#   def get(conn, params = %{"page" => page, "page_size" => page_size}) do
#     pagination_fields = [page: page, page_size: page_size]

#     case construct_query_from_conn_assigns(conn, params) do
#       :error ->
#         conn
#         |> halt_with(:not_found)

#       {query, params_used} ->
#         page = Repo.paginate(query, pagination_fields)
#         render_page(conn, "get.json", params_used ++ pagination_fields, page.entries, page)
#     end
#   end

#   def head(conn, params = %{"page" => page}) do
#     pagination_fields = [page: page, page_size: 1]

#     case construct_query_from_conn_assigns(conn, params) do
#       :error ->
#         conn
#         |> halt_with(:not_found)

#       {query, params_used} ->
#         page = Repo.paginate(query, pagination_fields)
#         render_page(conn, "get.json", params_used ++ pagination_fields, page.entries, page)
#     end
#   end

#   def describe(conn, params), do: get(conn, params)
# end
