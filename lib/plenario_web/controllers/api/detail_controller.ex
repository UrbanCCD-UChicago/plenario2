defmodule PlenarioWeb.Api.DetailController do
  use PlenarioWeb, :api_controller
  import Ecto.Query
  import PlenarioWeb.Api.Utils, only: [render_page: 5, map_to_query: 2]
  alias Plenario.{ModelRegistry, Repo}
  alias Plenario.Actions.MetaActions
  alias PlenarioWeb.Controllers.Api.CaptureArgs

  defmodule CaptureColumnArgs do
    import Plug.Conn

    def init(opts), do: opts

    def call(%Plug.Conn{"slug" => slug} = conn, opts) do
      columns = MetaActions.get(slug) |> MetaActions.get_column_names()
      CaptureArgs.call(conn, opts ++ [fields: columns])
    end
  end

  plug(CaptureArgs, assign: :geospatial_fields, fields: ["bbox"])
  plug(CaptureArgs, assign: :ordering_fields, fields: ["order_by"])
  plug(CaptureArgs, assign: :pagination_fields, fields: ["page", "page_size"])
  plug(CaptureColumnArgs, assign: :column_fields)

  def get(conn, %{"slug" => slug}) do
    IO.inspect(conn.assigns)
    pagination_params = Map.get(conn.assigns, :pagination_params)
    db_operation_params = Map.get(conn.assigns, :db_operation_params)
    column_params = Map.get(conn.assigns, :column_params)

    page =
      ModelRegistry.lookup(slug)
      |> map_to_query(db_operation_params)
      |> map_to_query(column_params)
      |> Repo.paginate(pagination_params)

    query_params = pagination_params ++ db_operation_params ++ column_params

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
