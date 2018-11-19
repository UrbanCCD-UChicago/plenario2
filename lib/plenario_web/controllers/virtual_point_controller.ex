defmodule PlenarioWeb.VirtualPointController do
  use PlenarioWeb, :controller

  import PlenarioWeb.FieldPlugs

  alias Plenario.{
    DataSet,
    FieldActions,
    VirtualPoint,
    VirtualPointActions
  }

  plug :assign_dsid
  plug :authorize_resource, model: DataSet, persisted: true, id_name: "data_set_id"
  plug :authorize_resource, model: VirtualPoint

  def new(conn, %{"data_set_id" => dsid}) do
    changeset = VirtualPoint.changeset(%VirtualPoint{data_set_id: dsid}, %{})

    fields =
      FieldActions.list(for_data_set: dsid)
      |> Enum.map(fn f -> {String.to_atom(f.name), f.id} end)
      |> Keyword.merge(["": nil])

    action = Routes.data_set_virtual_point_path(conn, :create, dsid)

    render conn, "new.html",
      changeset: changeset,
      fields: fields,
      action: action
  end

  def create(conn, %{"data_set_id" => dsid, "virtual_point" => form}) do
    VirtualPointActions.create(form)
    |> do_create(conn, dsid)
  end

  defp do_create({:ok, _}, conn, dsid) do
    conn
    |> put_flash(:success, "Created a new virtual point")
    |> redirect(to: Routes.data_set_path(conn, :show, dsid))
  end

  defp do_create({:error, changeset}, conn, dsid) do
    fields =
      FieldActions.list(for_data_set: dsid)
      |> Enum.map(fn f -> {String.to_atom(f.name), f.id} end)
      |> Keyword.merge(["": nil])

    action = Routes.data_set_virtual_point_path(conn, :create, dsid)

    conn
    |> put_status(:bad_request)
    |> put_error_flashes(changeset)
    |> render("new.html",
      changeset: changeset,
      fields: fields,
      action: action
    )
  end

  def edit(conn, %{"data_set_id" => dsid, "id" => id}) do
    virtual_point = VirtualPointActions.get!(id)
    changeset = VirtualPoint.changeset(virtual_point, %{})

    fields =
      FieldActions.list(for_data_set: dsid)
      |> Enum.map(fn f -> {String.to_atom(f.name), f.id} end)
      |> Keyword.merge(["": nil])

    action = Routes.data_set_virtual_point_path(conn, :update, dsid, virtual_point)

    render conn, "edit.html",
      virtual_point: virtual_point,
      changeset: changeset,
      fields: fields,
      action: action
  end

  def update(conn, %{"data_set_id" => dsid, "id" => id, "virtual_point" => form}) do
    virtual_point = VirtualPointActions.get!(id)
    VirtualPointActions.update(virtual_point, form)
    |> do_update(conn, dsid, virtual_point)
  end

  defp do_update({:ok, _}, conn, dsid, _) do
    conn
    |> put_flash(:success, "Updated virtual point")
    |> redirect(to: Routes.data_set_path(conn, :show, dsid))
  end

  defp do_update({:error, changeset}, conn, dsid, virtual_point) do
    fields =
      FieldActions.list(for_data_set: dsid)
      |> Enum.map(fn f -> {String.to_atom(f.name), f.id} end)
      |> Keyword.merge(["": nil])

    action = Routes.data_set_virtual_point_path(conn, :update, dsid, virtual_point)

    conn
    |> put_status(:bad_request)
    |> put_error_flashes(changeset)
    |> render("edit.html",
      virtual_point: virtual_point,
      changeset: changeset,
      fields: fields,
      action: action
    )
  end

  def delete(conn, %{"data_set_id" => dsid, "id" => id}) do
    virtual_point = VirtualPointActions.get!(id)
    {:ok, _} = VirtualPointActions.delete(virtual_point)

    conn
    |> put_flash(:info, "Virtual date deleted successfully.")
    |> redirect(to: Routes.data_set_path(conn, :show, dsid))
  end
end
