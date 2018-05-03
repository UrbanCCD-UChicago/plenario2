defmodule PlenarioWeb.Api.DetailController do
  use PlenarioWeb, :api_controller
  import Ecto.Query
  import PlenarioWeb.Api.Utils, only: [render_page: 5, map_to_query: 2]
  alias Plenario.{ModelRegistry, Repo}
  alias Plenario.Actions.MetaActions
  alias PlenarioWeb.Controllers.Api.CaptureArgs

  defmodule CaptureColumnArgs do
    def init(opts), do: opts

    def call(%Plug.Conn{:params => %{"slug" => slug}} = conn, opts) do
      columns = MetaActions.get(slug) |> MetaActions.get_column_names()
      CaptureArgs.call(conn, opts ++ [fields: columns])
    end
  end

  plug(CaptureArgs, assign: :geospatial_fields, fields: ["bbox"])
  plug(CaptureArgs, assign: :ordering_fields, fields: ["order_by"])
  plug(CaptureArgs, assign: :windowing_fields, fields: ["inserted_at", "updated_at"])
  plug(CaptureArgs, assign: :pagination_fields, fields: ["page", "page_size"])
  plug(CaptureColumnArgs, assign: :column_fields)

  def get(conn, %{"slug" => slug}) do
    IO.inspect(conn.assigns)

    geospatial_fields = Map.get(conn.assigns, :geospatial_fields)
    ordering_fields = Map.get(conn.assigns, :ordering_fields)
    windowing_fields = Map.get(conn.assigns, :windowing_fields)
    pagination_fields = Map.get(conn.assigns, :pagination_fields)
    column_fields = Map.get(conn.assigns, :column_fields)

    page =
      ModelRegistry.lookup(slug)
      |> map_to_query(geospatial_fields)
      |> map_to_query(ordering_fields)
      |> map_to_query(windowing_fields)
      |> map_to_query(column_fields)
      |> Repo.paginate(pagination_fields)

    query_params = geospatial_fields ++ ordering_fields ++ pagination_fields ++ column_fields

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
