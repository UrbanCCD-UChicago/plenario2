defmodule PlenarioWeb.Api.ListController do
  use PlenarioWeb, :api_controller

  alias Plenario.Repo
  alias Plenario.Schemas.Meta

  import Ecto.Query

  @associations [:fields, :unique_constraints, :virtual_dates, :virtual_points, :user]

  @doc """
  Lists all metadata objects satisfying the provided query.
  """
  def get(conn, %{}) do
    metas =
      from(meta in Meta, limit: 500)
      |> Repo.all()
      |> Enum.map(fn row -> Map.drop(row, @associations) end)
    render(conn, "get.json", %{metas: metas})
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
  https://stackoverflow.com/questions/34750899/render-many-to-many-relationship-json-in-phoenix-framework
  """
  def describe(conn, _params) do
    metas =
      from(meta in Meta, limit: 500)
      |> Repo.all()
      |> Enum.map(fn row -> Map.drop(row, @associations) end)
    render(conn, "describe.json", %{metas: metas})
  end
end
