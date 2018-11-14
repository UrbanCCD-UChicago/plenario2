defmodule PlenarioWeb.DataSetAdminController do
  use PlenarioWeb, :controller

  require Logger

  alias Plenario.{
    DataSetActions,
    VirtualDateActions,
    VirtualPointActions,
    Repo
  }

  def index(conn, _) do
    data_sets = DataSetActions.list(with_user: true)

    erred = Enum.filter(data_sets, & &1.state == "erred")
    approval = Enum.filter(data_sets, & &1.state == "awaiting_approval")
    first = Enum.filter(data_sets, & &1.state == "awaiting_first_import")
    live = Enum.filter(data_sets, & &1.state == "ready")

    render conn, "index.html",
      erred: erred,
      approval: approval,
      first: first,
      live: live
  end

  def review(conn, %{"id" => id}) do
    data_set = DataSetActions.get!(id, with_user: true, with_fields: true)
    dates = VirtualDateActions.list(for_data_set: data_set, with_fields: true)
    points = VirtualPointActions.list(for_data_set: data_set, with_fields: true)

    approve_action = Routes.data_set_admin_path(conn, :approve, data_set)
    reject_action = Routes.data_set_admin_path(conn, :reject, data_set)

    render conn, "review.html",
      data_set: data_set,
      dates: dates,
      points: points,
      approve_action: approve_action,
      reject_action: reject_action
  end

  def approve(conn, %{"id" => id}) do
    data_set = DataSetActions.get!(id)

    conn =
      try do
        :ok = Repo.up!(data_set)
        {:ok, _} = DataSetActions.update(data_set, state: "awaiting_first_import")
        conn
      rescue
        e in Exception ->
          Logger.error(e.message)
          put_flash(conn, :error, e.message)
      end

    redirect(conn, to: Routes.data_set_admin_path(conn, :index))
  end

  def reject(conn, %{"id" => id}) do
    data_set = DataSetActions.get!(id)
    {:ok, _} = DataSetActions.update(data_set, state: "new")

    redirect(conn, to: Routes.data_set_admin_path(conn, :index))
  end
end
