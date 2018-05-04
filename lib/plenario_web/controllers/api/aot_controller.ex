defmodule PlenarioWeb.Api.AotController do
  use PlenarioWeb, :api_controller
  alias Plenario.Actions.MetaActions
  alias PlenarioWeb.Controllers.Api.CaptureArgs

  @slug "array-of-things-chicago"
  @params %{"slug" => @slug}

  defmodule CaptureColumnArgs do
    @slug "array-of-things-chicago"

    def init(opts), do: opts

    def call(conn, opts) do
      columns = MetaActions.get_column_names(MetaActions.get(@slug))
      CaptureArgs.call(conn, opts ++ [fields: columns])
    end
  end

  plug(CaptureArgs, assign: :geospatial_fields, fields: ["bbox"])
  plug(CaptureArgs, assign: :ordering_fields, fields: ["order_by"])
  plug(CaptureArgs, assign: :windowing_fields, fields: ["inserted_at", "updated_at"])
  plug(CaptureArgs, assign: :pagination_fields, fields: ["page", "page_size"])
  plug(CaptureColumnArgs, assign: :column_fields)

  def get(conn, _), do: PlenarioWeb.Api.DetailController.get(%{conn | params: Map.merge(conn.params, @params)}, @params)
  def head(conn, _), do: PlenarioWeb.Api.DetailController.head(%{conn | params: Map.merge(conn.params, @params)}, @params)
  def describe(conn, _), do: PlenarioWeb.Api.DetailController.describe(%{conn | params: Map.merge(conn.params, @params)}, @params)
end
