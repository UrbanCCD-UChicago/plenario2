defmodule PlenarioWeb.Api.DetailController do
  alias Plenario.ModelRegistry
  alias Plenario.Repo
  import Ecto.Query
  import PlenarioWeb.Api.Utils, only: [render_page: 5, map_to_query: 2]
  use PlenarioWeb, :api_controller

  # assigns conn.assigns[:pagination_params]
  #   :page
  #   :page_size
  plug PlenarioWeb.Api.ParsePaginationParams

  # assigns conn.assigns[:db_operation_params]
  #   :inserted_at
  #   :updated_at
  plug PlenarioWeb.Api.ParseDbOperationParams

  # assigns conn.assigns[:column_params]
  #   :columns for MetaActions.get(:slug)
  plug PlenarioWeb.Controllers.Api.ParseColumnParams

  def get(conn, %{"slug" => slug}) do
    pagination_params = Map.get(conn.assigns, :pagination_params)
    db_operation_params = Map.get(conn.assigns, :db_operation_params)
    column_params = Map.get(conn.assigns, :column_params)

    page =
      ModelRegistry.lookup(slug)
      |> map_to_query(db_operation_params)
      |> map_to_query(column_params)
      |> Repo.paginate(pagination_params)

    query_params = pagination_params
      ++ db_operation_params
      ++ column_params

    render_page(conn, "get.json", query_params, page.entries, page)
  end

  def head(conn, %{"slug" => slug}) do
    entry = Repo.one(first(ModelRegistry.lookup(slug)))
    render(conn, "head.json", %{record: entry})
  end

  def describe(conn, %{"slug" => slug}) do
    pagination_params = Map.get(conn.assigns, :pagination_params)
    page = Repo.paginate(ModelRegistry.lookup(slug), pagination_params)
    render_page(conn, "get.json", pagination_params, page.entries, page)
  end
end
