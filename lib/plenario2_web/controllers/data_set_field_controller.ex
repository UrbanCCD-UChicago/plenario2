defmodule Plenario2Web.DataSetFieldController do
  alias Plenario2.Actions.{DataSetFieldActions, MetaActions}
  alias Plenario2.Changesets.DataSetFieldChangesets
  alias Plenario2.Repo
  alias Plenario2.Schemas.DataSetField
  use Plenario2Web, :controller

  def index(conn, %{"slug" => slug}) do
    meta = MetaActions.get_from_slug(slug)
    fields = DataSetFieldActions.list_for_meta(meta)

    render(conn, "index.html", slug: slug, meta: meta, fields: fields)
  end

  def new(conn, %{"slug" => slug}) do
    changeset = DataSetFieldChangesets.create(%DataSetField{})
    render(conn, "new.html", changeset: changeset, slug: slug)
  end

  def create(conn, %{"data_set_field" => params, "slug" => slug}) do
    meta = MetaActions.get_from_slug(slug)
    changeset_params = Map.merge(params, %{"meta_id" => meta.id})
    changeset = DataSetFieldChangesets.create(%DataSetField{}, changeset_params)

    case Repo.insert(changeset) do
      {:ok, field} ->
        conn
        |> put_flash(:info, "#{field.name} created!")
        |> redirect(to: meta_path(conn, :detail, slug))

      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset, slug: slug)
    end
  end

  def edit(conn, %{"slug"=> slug, "id" => id}) do
    field = Repo.get!(DataSetField, id)
    changeset = DataSetFieldChangesets.create(field)
    render(conn, "edit.html", field: field, changeset: changeset, slug: slug)
  end

  def update(conn, %{"slug" => slug, "id" => id, "data_set_field" => field_params}) do
    field = Repo.get!(DataSetField, id)
    changeset = DataSetFieldChangesets.create(field, field_params)

    case Repo.update(changeset) do
      {:ok, _field} ->
        conn
        |> put_flash(:info, "Data Set Field updated successfully.")
        |> redirect(to: meta_path(conn, :detail, slug))

      {:error, changeset} ->
        render(conn, "edit.html", video: field, changeset: changeset)
    end
  end
end
