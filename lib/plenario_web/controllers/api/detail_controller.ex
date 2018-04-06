defmodule PlenarioWeb.Api.DetailController do
  use PlenarioWeb, :api_controller

  alias Plenario.ModelRegistry
  alias Plenario.Repo

  import Ecto.Query

  def get(conn, %{"slug" => slug}) do
    records =
      from(r in ModelRegistry.lookup(slug), limit: 500)
      |> Repo.all()
    render(conn, "get.json", %{records: records})
  end

  def head(conn, %{"slug" => slug}) do
    record =
      first(ModelRegistry.lookup(slug))
      |> Repo.one()
    render(conn, "head.json", %{record: record})
  end

  def describe(conn, %{"slug" => slug}) do
    records =
      from(r in ModelRegistry.lookup(slug), limit: 500)
      |> Repo.all()
    render(conn, "describe.json", %{records: records})
  end
end
