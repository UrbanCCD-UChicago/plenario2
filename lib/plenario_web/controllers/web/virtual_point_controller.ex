defmodule PlenarioWeb.Web.VirtualPointController do
  use PlenarioWeb, :web_controller

  alias Plenario.Actions.VirtualPointFieldActions

  alias Plenario.Schemas.VirtualPointField

  alias PlenarioWeb.Web.ControllerUtils

  plug :authorize_resource, model: VirtualPointField

  def new(conn, %{"dsid" => dsid}) do
    changeset = VirtualPointFieldActions.new()
    action = virtual_point_path(conn, :create, dsid)
    field_choices = VirtualPointField.get_field_choices(dsid)
    render(conn, "create.html", changeset: changeset, action: action, dsid: dsid, field_choices: field_choices)
  end

  def create(conn, %{"dsid" => dsid, "virtual_point_field" => %{"lat_field_id" => lat, "loc_field_id" => loc, "lon_field_id" => lon, "meta_id" => meta_id}}) do
    res =
      case String.length(loc) == 0 do
        true -> VirtualPointFieldActions.create(meta_id, lat, lon)
        false -> VirtualPointFieldActions.create(meta_id, loc)
      end
    case res do
      {:ok, _} ->
        conn
        |> put_flash(:success, "Successfully created virtual point!")
        |> redirect(to: data_set_path(conn, :show, dsid))

      {:error, changeset} ->
        action = virtual_point_path(conn, :create, dsid)
        field_choices = VirtualPointField.get_field_choices(dsid)
        conn
        |> put_status(:bad_request)
        |> put_flash(:error, "Please review errors below.")
        |> ControllerUtils.flash_base_errors(changeset)
        |> render("create.html", changeset: changeset, action: action, dsid: dsid, field_choices: field_choices)
    end
  end

  def edit(conn, %{"dsid" => dsid, "id" => id}) do
    field = VirtualPointFieldActions.get(id)
    changeset = VirtualPointFieldActions.edit(field)
    action = virtual_point_path(conn, :update, dsid, id)
    field_choices = VirtualPointField.get_field_choices(dsid)
    render(conn, "edit.html", dsid: dsid, field: field, changeset: changeset, action: action, field_choices: field_choices)
  end

  def update(conn, %{"dsid" => dsid, "id" => id, "virtual_point_field" => %{} = params}) do
    field = VirtualPointFieldActions.get(id)
    opts = Enum.into(params, [])
    case VirtualPointFieldActions.update(field, opts) do
      {:ok, _} ->
        conn
        |> put_flash(:success, "Successfully updated virtual point!")
        |> redirect(to: data_set_path(conn, :show, dsid))

      {:error, changeset} ->
        action = virtual_point_path(conn, :update, dsid, id)
        field_choices = VirtualPointField.get_field_choices(dsid)
        conn
        |> put_status(:bad_request)
        |> put_flash(:error, "Please review errors below.")
        |> ControllerUtils.flash_base_errors(changeset)
        |> render("edit.html", dsid: dsid, changeset: changeset, action: action, dsid: dsid, field_choices: field_choices)
    end
  end

  def delete(conn, %{"dsid" => _,"id" => id}) do
    field = VirtualPointFieldActions.get(id)
    case VirtualPointFieldActions.delete(field) do
      {:ok, _} ->
        conn
        |> put_flash(:success, "Successfully deleted virtual point")
        |> redirect(to: data_set_path(conn, :show, field.meta_id))

      {:error, message} ->
        conn
        |> put_flash(:error, "Could not delete field: #{message}")
        |> redirect(to: data_set_path(conn, :show, field.meta_id))
    end
  end
end
