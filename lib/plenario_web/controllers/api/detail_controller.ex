defmodule PlenarioWeb.Api.DetailController do
  use PlenarioWeb, :api_controller

  alias Plenario.ModelRegistry
  alias Plenario.Repo

  import Ecto.Query
  import PlenarioWeb.Api.Utils, only: [render_page: 5]

  # assigns conn.assigns[:pagination_params]
  plug PlenarioWeb.Api.ParsePaginationParams

  def get(conn, %{"slug" => slug}) do
    pagination_params = Map.get(conn.assigns, :pagination_params)
    page = Repo.paginate(ModelRegistry.lookup(slug), pagination_params)
    render_page(conn, "get.json", pagination_params, page.entries, page)
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
