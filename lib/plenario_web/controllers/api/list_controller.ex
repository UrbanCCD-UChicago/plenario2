defmodule PlenarioWeb.Api.ListController do
  use PlenarioWeb, :api_controller

  alias Plenario.Repo
  alias Plenario.Schemas.Meta

  import Ecto.Query
  import PlenarioWeb.Api.Utils, only: [render_page: 5]

  # assigns conn.assigns[:pagination_params]
  plug PlenarioWeb.Api.ParsePaginationParams

  @associations [:fields, :unique_constraints, :virtual_dates, :virtual_points, :user]

  @doc """
  Lists all metadata objects satisfying the provided query.
  """
  def get(conn, _params) do
    pagination_params = Map.get(conn.assigns, :pagination_params)
    page = Repo.paginate(Meta, pagination_params)
    entries = Enum.map(page.entries, fn row -> Map.drop(row, @associations) end)
    render_page(conn, "get.json", pagination_params, entries, page)
  end

  @doc """
  Lists a single metadata object satisfying the provided query.
  """
  def head(conn, _params) do
    meta = first(Meta) |> Repo.one() |> Map.drop(@associations)
    render(conn, "head.json", %{meta: meta})
  end

  @doc """
  Lists all single metadata objects satisfying the provided query. The metadata
  objects have all associations preloaded.
  """
  def describe(conn, _params) do
    pagination_params = Map.get(conn.assigns, :pagination_params)
    page =
      from(meta in Meta, preload: ^@associations)
      |> Repo.paginate(pagination_params)
    entries = page.entries
    render_page(conn, "get.json", pagination_params, entries, page)
  end

end
