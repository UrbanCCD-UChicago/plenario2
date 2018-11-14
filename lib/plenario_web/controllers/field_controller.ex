defmodule PlenarioWeb.FieldController do
  use PlenarioWeb, :controller

  import PlenarioWeb.FieldPlugs

  alias Plenario.{
    DataSet,
    Field,
    FieldActions
  }

  plug :assign_dsid
  plug :authorize_resource, model: DataSet, persisted: true, id_name: "data_set_id"
  plug :authorize_resource, model: Field

  def edit(conn, %{"data_set_id" => dsid, "id" => id}) do
    field = FieldActions.get!(id)
    changeset = Field.changeset(field, %{})
    action = Routes.data_set_field_path(conn, :update, dsid, field)

    render conn, "edit.html",
      field: field,
      changeset: changeset,
      action: action
  end

  def update(conn, %{"data_set_id" => dsid, "id" => id, "field" => form}) do
    field = FieldActions.get!(id)

    FieldActions.update(field, form)
    |> do_update(conn, dsid, field)
  end

  defp do_update({:ok, _}, conn, dsid, _) do
    conn
    |> put_flash(:info, "Field updated successfully.")
    |> redirect(to: Routes.data_set_path(conn, :show, dsid))
  end

  defp do_update({:error, changeset}, conn, dsid, field) do
    action = Routes.data_set_field_path(conn, :update, dsid, field)

    conn
    |> put_status(:bad_request)
    |> put_error_flashes(changeset)
    |> render("edit.html",
      field: field,
      changeset: changeset,
      action: action
    )
  end

  # def delete(conn, %{"data_set_id" => dsid, "id" => id}) do
  #   field = FieldActions.get!(id)
  #   {:ok, _field} = FieldActions.delete(field)

  #   conn
  #   |> put_flash(:info, "Field deleted successfully.")
  #   |> redirect(to: Routes.data_set_path(conn, :show, dsid))
  # end
end
