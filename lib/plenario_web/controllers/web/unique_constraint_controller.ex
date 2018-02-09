defmodule PlenarioWeb.Web.UniqueConstraintController do
  use PlenarioWeb, :web_controller

  alias Plenario.Actions.UniqueConstraintActions

  alias Plenario.Schemas.UniqueConstraint

  alias PlenarioWeb.Web.ControllerUtils

  plug :authorize_resource, model: UniqueConstraint

  def new(conn, %{"dsid" => dsid}) do
    changeset = UniqueConstraintActions.new()
    action = unique_constraint_path(conn, :create, dsid)
    field_choices = UniqueConstraint.get_field_choices(dsid)
    render(conn, "create.html", changeset: changeset, action: action, dsid: dsid, field_choices: field_choices)
  end

  def create(conn, %{"dsid" => _, "unique_constraint" => %{"meta_id" => meta_id, "field_ids" => field_ids}}) do
    case UniqueConstraintActions.create(meta_id, field_ids) do
      {:ok, _} ->
        conn
        |> put_flash(:success, "Successfully created constraint!")
        |> redirect(to: data_set_path(conn, :show, meta_id))

      {:error, changeset} ->
        action = unique_constraint_path(conn, :create, meta_id)
        field_choices = UniqueConstraint.get_field_choices(meta_id)
        conn
        |> put_status(:bad_request)
        |> put_flash(:error, "Please review errors below.")
        |> ControllerUtils.flash_base_errors(changeset)
        |> render("create.html", changeset: changeset, action: action, dsid: meta_id, field_choices: field_choices)
    end
  end

  def edit(conn, %{"dsid" => dsid, "id" => id}) do
    constraint = UniqueConstraintActions.get(id)
    changeset = UniqueConstraintActions.edit(constraint)
    action = unique_constraint_path(conn, :update, constraint.meta_id, id)
    field_choices = UniqueConstraint.get_field_choices(dsid)
    render(conn, "edit.html", constraint: constraint, changeset: changeset, action: action, field_choices: field_choices)
  end

  def update(conn, %{"dsid" => dsid, "id" => id, "unique_constraint" => %{"field_ids" => field_ids}}) do
    constraint = UniqueConstraintActions.get(id)
    case UniqueConstraintActions.update(constraint, field_ids: field_ids) do
      {:ok, constraint} ->
        conn
        |> put_flash(:success, "Successfully updated constraint #{constraint.name}!")
        |> redirect(to: data_set_path(conn, :show, constraint.meta_id))

      {:error, changeset} ->
        action = unique_constraint_path(conn, :update, constraint.meta_id, id)
        field_choices = UniqueConstraint.get_field_choices(dsid)
        conn
        |> put_status(:bad_request)
        |> put_flash(:error, "Please review errors below.")
        |> ControllerUtils.flash_base_errors(changeset)
        |> render("edit.html", constraint: constraint, changeset: changeset, action: action, field_choices: field_choices)
    end
  end

  def delete(conn, %{"dsid" => _,"id" => id}) do
    constraint = UniqueConstraintActions.get(id)
    case UniqueConstraintActions.delete(constraint) do
      {:ok, _} ->
        conn
        |> put_flash(:success, "Successfully deleted constraint #{constraint.name}")
        |> redirect(to: data_set_path(conn, :show, constraint.meta_id))

      {:error, message} ->
        conn
        |> put_flash(:error, "Could not delete constraint: #{message}")
        |> redirect(to: data_set_path(conn, :show, constraint.meta_id))
    end
  end
end
