defmodule Plenario2Web.DataSetFieldController do
  alias Plenario2.Actions.{DataSetFieldActions, MetaActions}
  alias Plenario2.Changesets.DataSetFieldChangesets
  alias Plenario2.Repo
  alias Plenario2.Schemas.DataSetField
  use Plenario2Web, :controller

  def index(conn, params) do
    slug = params["data_set_slug"]
    meta = MetaActions.get_from_slug(slug)
    fields = DataSetFieldActions.list_for_meta(meta)

    render conn, "index.html", slug: slug, meta: meta, fields: fields
  end

  def new(conn, params) do
    slug = params["data_set_slug"]
    meta = MetaActions.get_from_slug(slug)
    source = meta.source_url
    changeset = DataSetFieldChangesets.create %DataSetField{}
    
    render conn, "new.html", [
      changeset: changeset, 
      slug: slug
    ]
  end

  def create(conn, params) do
    data_set_field_params = params["data_set_field"]
    slug = params["data_set_slug"]
    meta = MetaActions.get_from_slug(slug)

    changeset = DataSetFieldChangesets.create(
      %DataSetField{}, 
      Map.merge(data_set_field_params, %{"meta_id" => meta.id})
    )

   case Repo.insert(changeset) do
      {:ok, field} ->
        conn
        |> put_flash(:info, "#{field.name} created!")
        |> redirect(to: data_set_field_path(conn, :index, slug))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset, slug: slug)
    end
  end

  def show(conn, params) do

  end
end