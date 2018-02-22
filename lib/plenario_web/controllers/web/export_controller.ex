defmodule PlenarioWeb.Web.ExportController do
  use PlenarioWeb, :web_controller

  import Ecto.Query

  alias Plenario.Actions.MetaActions

  alias PlenarioEtl.Actions.ExportJobActions

  alias PlenarioEtl.Exporter

  alias Plenario.{ModelRegistry, Repo}

  def export_meta(conn, %{"meta_id" => meta_id}) do
    meta = MetaActions.get(meta_id)
    user = Guardian.Plug.current_resource(conn)

    if user == nil do
      conn
      |> put_flash(:error, "You must sign in to export data sets.")
      |> redirect(to: auth_path(conn, :index))
    end

    model = ModelRegistry.lookup(meta.slug)
    query = from(m in model)
    query_string = inspect(query, structs: false)

    case ExportJobActions.create(meta, user, query_string, false) do
      {:ok, job} ->
        job = Repo.preload(job, :meta)
        case Exporter.export_task(job) do
          {:ok, _} ->
            conn
            |> put_flash(:success, "Export started! You'll be emailed soon with a link.")
            |> redirect(to: page_path(conn, :explorer))

          {:error, _} ->
            conn
            |> put_flash(:error, "There was a problem creating your export request.")
            |> redirect(to: page_path(conn, :explorer))
        end

      {:error, _} ->
        conn
        |> put_flash(:error, "There was a problem creating your export request.")
        |> redirect(to: page_path(conn, :explorer))
    end
  end
end
