defmodule Plenario2Web.DataSetFieldController do
  alias Plenario2.Actions.{DataSetFieldActions, MetaActions}
  alias Plenario2.Schemas.DataSetField
  use Plenario2Web, :controller

  def index(conn, params) do
    slug = params["data_set_slug"]
    meta = MetaActions.get_from_slug(slug)
    fields = DataSetFieldActions.list_for_meta(meta)
    render conn, "index.html", slug: slug, meta: meta, fields: fields
  end

  def show(conn, params) do

  end

  def new(conn, params) do
    changeset = DataSetField.changeset %DataSetField{}
    render conn, "new.html", changeset: changeset
  end

  def create(conn, params) do

  end
end