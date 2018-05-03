defmodule PlenarioWeb.Api.ListController do
  use PlenarioWeb, :api_controller
  import Ecto.Query
  import PlenarioWeb.Api.Utils, only: [render_page: 5, map_to_query: 2]
  alias Plenario.Repo
  alias Plenario.Schemas.Meta
  alias PlenarioWeb.Controllers.Api.CaptureArgs

  defmodule CaptureColumnArgs do
    def init(opts), do: opts

    def call(conn, opts) do
      columns = 
        Map.keys(Meta.__struct__) 
        |> Enum.map(&to_string/1)
      CaptureArgs.call(conn, opts ++ [fields: columns])
    end
  end

  plug(CaptureArgs, assign: :geospatial_fields, fields: ["bbox"])
  plug(CaptureArgs, assign: :ordering_fields, fields: ["order_by"])
  plug(CaptureArgs, assign: :windowing_fields, fields: ["inserted_at", "updated_at"])
  plug(CaptureArgs, assign: :pagination_fields, fields: ["page", "page_size"])
  plug(CaptureColumnArgs, assign: :column_fields)

  @associations [:fields, :unique_constraints, :virtual_dates, :virtual_points, :user]

  def construct_query_from_conn_assigns(conn) do
    geospatial_fields = Map.get(conn.assigns, :geospatial_fields)
    ordering_fields = Map.get(conn.assigns, :ordering_fields)
    windowing_fields = Map.get(conn.assigns, :windowing_fields)
    column_fields = Map.get(conn.assigns, :column_fields)

    query = 
      Meta
      |> map_to_query(geospatial_fields)
      |> map_to_query(ordering_fields)
      |> map_to_query(windowing_fields)
      |> map_to_query(column_fields)
    
    params = geospatial_fields ++ windowing_fields ++ ordering_fields ++ column_fields

    {query, params}
  end

  @doc """
  Lists all metadata objects satisfying the provided query.
  """
  def get(conn, _params) do
    pagination_fields = Map.get(conn.assigns, :pagination_fields)
    {query, params_used} = construct_query_from_conn_assigns(conn)
    page = Repo.paginate(query, pagination_fields)
    render_page(conn, "get.json", params_used ++ pagination_fields, page.entries, page)
  end

  def head(conn, params) do
    pagination_fields = Map.get(conn.assigns, :pagination_fields)
    {query, params_used} = construct_query_from_conn_assigns(conn)
    page = Repo.paginate(query, page_size: 1, page: 1)
    render_page(conn, "get.json", params_used ++ pagination_fields, page.entries, page)
  end

  @doc """
  Lists all single metadata objects satisfying the provided query. The metadata
  objects have all associations preloaded.
  """
  def describe(conn, _params) do
    pagination_fields = Map.get(conn.assigns, :pagination_fields)
    {query, params_used} = construct_query_from_conn_assigns(conn)
    page = Repo.paginate(preload(query, ^@associations), pagination_fields)
    render_page(conn, "get.json", params_used ++ pagination_fields, page.entries, page)
  end
end
