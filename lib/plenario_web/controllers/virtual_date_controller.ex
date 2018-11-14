defmodule PlenarioWeb.VirtualDateController do
  use PlenarioWeb, :controller

  import PlenarioWeb.FieldPlugs

  alias Plenario.{
    DataSet,
    FieldActions,
    VirtualDate,
    VirtualDateActions
  }

  plug :assign_dsid
  plug :authorize_resource, model: DataSet, persisted: true, id_name: "data_set_id"
  plug :authorize_resource, model: VirtualDate

  def new(conn, %{"data_set_id" => dsid}) do
    changeset = VirtualDate.changeset(%VirtualDate{data_set_id: dsid}, %{})

    fields =
      FieldActions.list(for_data_set: dsid)
      |> Enum.map(fn f -> {String.to_atom(f.name), f.id} end)
      |> Keyword.merge(["": nil])

    action = Routes.data_set_virtual_date_path(conn, :create, dsid)

    render conn, "new.html",
      changeset: changeset,
      fields: fields,
      action: action
  end

  def create(conn, %{"data_set_id" => dsid, "virtual_date" => form}) do
    VirtualDateActions.create(form)
    |> do_create(conn, dsid)
  end

  defp do_create({:ok, _}, conn, dsid) do
    conn
    |> put_flash(:success, "Created a new virtual date")
    |> redirect(to: Routes.data_set_path(conn, :show, dsid))
  end

  defp do_create({:error, changeset}, conn, dsid) do
    fields =
      FieldActions.list(for_data_set: dsid)
      |> Enum.map(fn f -> {String.to_atom(f.name), f.id} end)
      |> Keyword.merge(["": nil])

    action = Routes.data_set_virtual_date_path(conn, :create, dsid)

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
    virtual_date = VirtualDateActions.get!(id)
    changeset = VirtualDate.changeset(virtual_date, %{})

    fields =
      FieldActions.list(for_data_set: dsid)
      |> Enum.map(fn f -> {String.to_atom(f.name), f.id} end)
      |> Keyword.merge(["": nil])

    action = Routes.data_set_virtual_date_path(conn, :update, dsid, virtual_date)

    render conn, "edit.html",
      virtual_date: virtual_date,
      changeset: changeset,
      fields: fields,
      action: action
  end

  def update(conn, %{"data_set_id" => dsid, "id" => id, "virtual_date" => form}) do
    virtual_date = VirtualDateActions.get!(id)
    VirtualDateActions.update(virtual_date, form)
    |> do_update(conn, dsid, virtual_date)
  end

  defp do_update({:ok, _}, conn, dsid, _) do
    conn
    |> put_flash(:success, "Updated virtual date")
    |> redirect(to: Routes.data_set_path(conn, :show, dsid))
  end

  defp do_update({:error, changeset}, conn, dsid, virtual_date) do
    fields =
      FieldActions.list(for_data_set: dsid)
      |> Enum.map(fn f -> {String.to_atom(f.name), f.id} end)
      |> Keyword.merge(["": nil])

    action = Routes.data_set_virtual_date_path(conn, :update, dsid, virtual_date)

    conn
    |> put_status(:bad_request)
    |> put_error_flashes(changeset)
    |> render("edit.html",
      virtual_date: virtual_date,
      changeset: changeset,
      fields: fields,
      action: action
    )
  end

  def delete(conn, %{"data_set_id" => dsid, "id" => id}) do
    virtual_date = VirtualDateActions.get!(id)
    {:ok, _} = VirtualDateActions.delete(virtual_date)

    conn
    |> put_flash(:info, "Virtual date deleted successfully.")
    |> redirect(to: Routes.data_set_path(conn, :show, dsid))
  end
end
