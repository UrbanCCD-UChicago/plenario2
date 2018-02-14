defmodule PlenarioWeb.Web.VirtualDateController do
  use PlenarioWeb, :web_controller

  alias Plenario.Actions.VirtualDateFieldActions

  alias Plenario.Schemas.VirtualDateField

  alias PlenarioWeb.Web.ControllerUtils

  plug :authorize_resource, model: VirtualDateField

  def new(conn, %{"dsid" => dsid}) do
    changeset = VirtualDateFieldActions.new()
    action = virtual_date_path(conn, :create, dsid)
    field_choices = VirtualDateField.get_field_choices(dsid)
    render(conn, "create.html", changeset: changeset, action: action, dsid: dsid, field_choices: field_choices)
  end

  def create(conn, %{"dsid" => dsid, "virtual_date_field" => %{"meta_id" => meta_id, "year_field_id" => yr_id} = params}) do
    opts = Enum.map(params, fn {key, value} -> {:"#{key}", value} end)
    case VirtualDateFieldActions.create(meta_id, yr_id, opts) do
      {:ok, _} ->
        conn
        |> put_flash(:success, "Successfully created virtual date!")
        |> redirect(to: data_set_path(conn, :show, dsid))

      {:error, changeset} ->
        action = virtual_date_path(conn, :create, dsid)
        field_choices = VirtualDateField.get_field_choices(dsid)
        conn
        |> put_status(:bad_request)
        |> put_flash(:error, "Please review errors below.")
        |> ControllerUtils.flash_base_errors(changeset)
        |> render("create.html", changeset: changeset, action: action, dsid: dsid, field_choices: field_choices)
    end
  end

  def edit(conn, %{"dsid" => dsid, "id" => id}) do
    field = VirtualDateFieldActions.get(id)
    changeset = VirtualDateFieldActions.edit(field)
    action = virtual_date_path(conn, :update, dsid, id)
    field_choices = VirtualDateField.get_field_choices(dsid)
    render(conn, "edit.html", field: field, changeset: changeset, action: action, field_choices: field_choices)
  end

  def update(conn, %{"dsid" => dsid, "id" => id, "virtual_date_field" => %{} = params}) do
    field = VirtualDateFieldActions.get(id)
    opts = Enum.into(params, [])
    case VirtualDateFieldActions.update(field, opts) do
      {:ok, _} ->
        conn
        |> put_flash(:success, "Successfully updated virtual date!")
        |> redirect(to: data_set_path(conn, :show, dsid))

      {:error, changeset} ->
        action = virtual_date_path(conn, :update, dsid, id)
        field_choices = VirtualDateField.get_field_choices(dsid)
        conn
        |> put_status(:bad_request)
        |> put_flash(:error, "Please review errors below.")
        |> ControllerUtils.flash_base_errors(changeset)
        |> render("edit.html", changeset: changeset, action: action, dsid: dsid, field_choices: field_choices)
    end
  end

  def delete(conn, %{"dsid" => _,"id" => id}) do
    field = VirtualDateFieldActions.get(id)
    case VirtualDateFieldActions.delete(field) do
      {:ok, _} ->
        conn
        |> put_flash(:success, "Successfully deleted virtual date")
        |> redirect(to: data_set_path(conn, :show, field.meta_id))

      {:error, message} ->
        conn
        |> put_flash(:error, "Could not delete field: #{message}")
        |> redirect(to: data_set_path(conn, :show, field.meta_id))
    end
  end
end
