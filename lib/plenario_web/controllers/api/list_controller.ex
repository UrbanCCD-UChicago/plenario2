defmodule PlenarioWeb.Api.ListController do
  use PlenarioWeb, :api_controller

  alias Plenario.Repo
  alias Plenario.Schemas.Meta

  import Ecto.Query

  @keywords ["page", "page_number"]
  @associations [:fields, :unique_constraints, :virtual_dates, :virtual_points, :user]

  @doc """
  Lists all metadata objects satisfying the provided query.
  """
  def get(conn, params) do
    {filters, unused} = Map.split(params, @keywords)
    kw_filters = Enum.map(filters, fn {k, v} -> {String.to_atom(k), v} end)

    page =
      from(meta in Meta, limit: 500)
      |> Repo.paginate(kw_filters)

    entries =
      page.entries
      |> Enum.map(fn row -> Map.drop(row, @associations) end)

    render(conn, "get.json", %{
      params: filters,
      count: length(entries),
      total_pages: page.total_pages,
      total_records: page.total_entries,
      metas: entries})
  end

  @doc """
  Lists a single metadata object satisfying the provided query.
  """
  def head(conn, _params) do
    meta =
      first(Meta)
      |> Repo.one()
      |> Map.drop(@associations)
    render(conn, "head.json", %{meta: meta})
  end

  @doc """
  Lists all single metadata objects satisfying the provided query. The metadata
  objects have all associations preloaded.
  """
  def describe(conn, _params) do
    metas =
      from(meta in Meta, limit: 500, preload: ^@associations)
      |> Repo.all()
    render(conn, "describe.json", %{metas: metas})
  end
end
