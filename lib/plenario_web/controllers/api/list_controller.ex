defmodule PlenarioWeb.Api.ListController do
  use PlenarioWeb, :api_controller

  alias Plenario.Repo
  alias Plenario.Schemas.Meta
  alias PlenarioWeb.Api.Response

  import Ecto.Query

  # todo(heyzoos): return all results for a query
  def get(conn, %{}) do
    metas =
      from(meta in Meta, limit: 500)
      |> Repo.all()
    render(conn, "get.json", %{})
  end

  # todo(heyzoos): return a single result for a query
  def head(conn, _params) do
    render(conn, "head.json", %{})
  end

  # todo(heyzoos): describe the `Meta` schema
  def describe(conn, _params) do
    render(conn, "describe.json", %{})
  end
end
