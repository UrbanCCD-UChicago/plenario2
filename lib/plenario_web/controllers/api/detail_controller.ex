defmodule PlenarioWeb.Api.DetailController do
  use PlenarioWeb, :api_controller
  import PlenarioWeb.Api.Utils, only: [render_page: 5, map_to_query: 2]
  alias Plenario.{ModelRegistry, Repo}
  alias Plenario.Actions.MetaActions
  alias Plenario.Schemas.{VirtualPointField}
  alias PlenarioWeb.Controllers.Api.CaptureArgs

  defmodule CaptureColumnArgs do
    def init(opts), do: opts

    def call(conn, opts) do
      meta = MetaActions.get(conn.params["slug"], with_virtual_points: true) 
      columns = MetaActions.get_column_names(meta)
      vpfs = 
        meta.virtual_points()
        |> Enum.map(fn vpf -> vpf.name() end)
      CaptureArgs.call(conn, opts ++ [fields: columns ++ vpfs])
    end
  end

  defmodule CaptureBboxArg do
    def init(opts), do: opts

    def call(%Plug.Conn{params: %{"bbox" => geojson}} = conn, opts) do
      meta = MetaActions.get(conn.params["slug"], with_virtual_points: true)
      geom = Poison.decode!(geojson) |>  Geo.JSON.decode()
      geom = %{geom | srid: 4326}

      vpf_query_map = 
        meta.virtual_points()
        |> Stream.map(fn vpf -> vpf.name() end)
        |> Enum.map(fn vpf_name -> {vpf_name, {"in", geom}} end)

      assign(conn, opts[:assign], vpf_query_map)
    end

    def call(conn, opts) do
      assign(conn, opts[:assign], [])
    end
  end

  plug(CaptureArgs, assign: :ordering_fields, fields: ["order_by"])
  plug(CaptureArgs, assign: :windowing_fields, fields: ["inserted_at", "updated_at"])
  plug(CaptureArgs, assign: :pagination_fields, fields: ["page", "page_size"])
  plug(CaptureColumnArgs, assign: :column_fields)
  plug(CaptureBboxArg, assign: :bbox_fields)

  def construct_query_from_conn_assigns(conn, %{"slug" => slug}) do
    ordering_fields = Map.get(conn.assigns, :ordering_fields)
    windowing_fields = Map.get(conn.assigns, :windowing_fields)
    column_fields = Map.get(conn.assigns, :column_fields)
    bbox_query_map = Map.get(conn.assigns, :bbox_fields)

    query = 
      ModelRegistry.lookup(slug)
      |> map_to_query(ordering_fields)
      |> map_to_query(windowing_fields)
      |> map_to_query(column_fields)
      |> map_to_query(bbox_query_map)
    
    params = windowing_fields ++ ordering_fields ++ column_fields ++ bbox_query_map

    {query, params}
  end

  def get(conn, params) do
    pagination_fields = Map.get(conn.assigns, :pagination_fields)
    {query, params_used} = construct_query_from_conn_assigns(conn, params)
    page = Repo.paginate(query, pagination_fields)
    render_page(conn, "get.json", params_used ++ pagination_fields, page.entries, page)
  end

  def head(conn, params) do
    pagination_fields = Map.get(conn.assigns, :pagination_fields)
    {query, params_used} = construct_query_from_conn_assigns(conn, params)
    page = Repo.paginate(query, page_size: 1, page: 1)
    render_page(conn, "get.json", params_used ++ pagination_fields, page.entries, page)
  end

  def describe(conn, params), do: get(conn, params)
end
