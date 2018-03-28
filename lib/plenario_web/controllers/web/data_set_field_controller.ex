defmodule PlenarioWeb.Web.DataSetFieldController do
  use PlenarioWeb, :web_controller

  alias Plenario.Actions.DataSetFieldActions

  alias Plenario.Schemas.DataSetField

  alias PlenarioWeb.Web.ControllerUtils

  plug :authorize_resource, model: DataSetField

  def edit(conn, %{"dsid" => _, "id" => id}) do
    field = DataSetFieldActions.get(id)
    do_edit(field, id, conn)
  end

  defp do_edit(nil, _, conn), do: do_404(conn)
  defp do_edit(%DataSetField{} = field, id, conn) do
    changeset = DataSetFieldActions.edit(field)
    action = data_set_field_path(conn, :update, field.meta_id, id)
    type_choices = DataSetField.get_type_choices()
    render(conn, "edit.html", field: field, changeset: changeset, action: action, type_choices: type_choices)
  end

  def update(conn, %{"dsid" => _,"id" => id, "data_set_field" => %{"description" => description, "type" => type}}) do
    field = DataSetFieldActions.get(id)
    do_update(field, id, type, description, conn)
  end

  defp do_update(nil, _, _, _, conn), do: do_404(conn)
  defp do_update(%DataSetField{} = field, id, type, description, conn) do
    case DataSetFieldActions.update(field, type: type, description: description) do
      {:ok, field} ->
        conn
        |> put_flash(:success, "Successfully updated field #{field.name}!")
        |> redirect(to: data_set_path(conn, :show, field.meta_id))

      {:error, changeset} ->
        action = data_set_field_path(conn, :update, field.meta_id, id)
        type_choices = DataSetField.get_type_choices()
        conn
        |> put_status(:bad_request)
        |> put_flash(:error, "Please review errors below.")
        |> ControllerUtils.flash_base_errors(changeset)
        |> render("edit.html", field: field, changeset: changeset, action: action, type_choices: type_choices)
    end
  end

  def delete(conn, %{"dsid" => _,"id" => id}) do
    field = DataSetFieldActions.get(id)
    do_delete(field, conn)
  end

  defp do_delete(nil, conn), do: do_404(conn)
  defp do_delete(%DataSetField{} = field, conn) do
    case DataSetFieldActions.delete(field) do
      {:ok, _} ->
        conn
        |> put_flash(:success, "Successfully deleted field #{field.name}")
        |> redirect(to: data_set_path(conn, :show, field.meta_id))

      {:error, message} ->
        conn
        |> put_flash(:error, "Could not delete field: #{message}")
        |> redirect(to: data_set_path(conn, :show, field.meta_id))
    end
  end
end
