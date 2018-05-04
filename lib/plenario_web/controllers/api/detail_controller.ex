defmodule PlenarioWeb.Api.DetailController do
  use PlenarioWeb, :api_controller
  import PlenarioWeb.Api.Utils, only: [render_page: 5, map_to_query: 2]
  alias Plenario.Actions.MetaActions
  alias Plenario.{ModelRegistry, Repo}
  alias PlenarioWeb.Controllers.Api.CaptureArgs

  defmodule CaptureColumnArgs do
    def init(opts), do: opts

    def call(conn, opts) do
      columns = 
        conn.params["slug"]
        |> MetaActions.get()
        |> MetaActions.get_column_names()
      CaptureArgs.call(conn, opts ++ [fields: columns])
    end
  end

  plug(CaptureArgs, assign: :geospatial_fields, fields: ["bbox"])
  plug(CaptureArgs, assign: :ordering_fields, fields: ["order_by"])
  plug(CaptureArgs, assign: :windowing_fields, fields: ["inserted_at", "updated_at"])
  plug(CaptureArgs, assign: :pagination_fields, fields: ["page", "page_size"])
  plug(CaptureColumnArgs, assign: :column_fields)

  def construct_query_from_conn_assigns(conn, %{"slug" => slug}) do
    geospatial_fields = Map.get(conn.assigns, :geospatial_fields)
    ordering_fields = Map.get(conn.assigns, :ordering_fields)
    windowing_fields = Map.get(conn.assigns, :windowing_fields)
    column_fields = Map.get(conn.assigns, :column_fields)

    query = 
      ModelRegistry.lookup(slug)
      |> map_to_query(geospatial_fields)
      |> map_to_query(ordering_fields)
      |> map_to_query(windowing_fields)
      |> map_to_query(column_fields)
    
    params = geospatial_fields ++ windowing_fields ++ ordering_fields ++ column_fields

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
