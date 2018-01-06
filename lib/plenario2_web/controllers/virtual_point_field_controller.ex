defmodule Plenario2Web.VirtualPointFieldController do
  use Plenario2Web, :controller

  alias Plenario2.Actions.{MetaActions, VirtualPointFieldActions}
  alias Plenario2.Changesets.VirtualPointFieldChangesets
  alias Plenario2.Schemas.VirtualPointField

  def get_create_loc(conn, %{"slug" => meta_slug}) do
    meta = MetaActions.get(meta_slug, [with_fields: true])
    changeset = VirtualPointFieldChangesets.blank_loc(%VirtualPointField{})
    action = virtual_point_field_path(conn, :do_create_loc, meta_slug)

    text_fields = Enum.filter(meta.data_set_fields, fn f -> f.type == "text" end)
    fields = for f <- text_fields, do: f.name

    render(conn, "create_loc.html", meta: meta, fields: fields, changeset: changeset, action: action)
  end

  def do_create_loc(conn, %{"slug" => meta_slug, "virtual_point_field" => params}) do
    VirtualPointFieldActions.create_from_loc(params["meta_id"], params["location_field"])
    |> create_loc_reply(conn, meta_slug)
  end

  defp create_loc_reply({:ok, _}, conn, meta_slug) do
    conn
    |> put_flash(:success, "Location Field Created")
    |> redirect(to: meta_path(conn, :detail, meta_slug))
  end

  defp create_loc_reply({:error, changeset}, conn, meta_slug) do
    meta = MetaActions.get(meta_slug, [with_fields: true])
    action = virtual_point_field_path(conn, :do_create_loc, meta_slug)

    text_fields = Enum.filter(meta.data_set_fields, fn f -> f.type == "text" end)
    fields = for f <- text_fields, do: f.name

    conn
    |> put_flash(:error, "Please review and fix errors below")
    |> render("create_loc.html", meta: meta, fields: fields, changeset: changeset, action: action)
  end

  def get_create_longlat(conn, %{"slug" => meta_slug}) do
    meta = MetaActions.get(meta_slug, [with_fields: true])
    changeset = VirtualPointFieldChangesets.blank_long_lat(%VirtualPointField{})
    action = virtual_point_field_path(conn, :do_create_longlat, meta_slug)

    float_fields = Enum.filter(meta.data_set_fields, fn f -> f.type == "float" end)
    fields = for f <- float_fields, do: f.name

    render(conn, "create_long_lat.html", meta: meta, fields: fields, changeset: changeset, action: action)
  end

  def do_create_longlat(conn, %{"slug" => meta_slug, "virtual_point_field" => params}) do
    VirtualPointFieldActions.create_from_long_lat(params["meta_id"], params["longitude_field"], params["latitude_field"])
    |> create_longlat_reply(conn, meta_slug)
  end

  defp create_longlat_reply({:ok, _}, conn, meta_slug) do
    conn
    |> put_flash(:success, "Location Field Created")
    |> redirect(to: meta_path(conn, :detail, meta_slug))
  end

  defp create_longlat_reply({:error, changeset}, conn, meta_slug) do
    meta = MetaActions.get(meta_slug, [with_fields: true])
    action = virtual_point_field_path(conn, :do_create_longlat, meta_slug)

    float_fields = Enum.filter(meta.data_set_fields, fn f -> f.type == "float" end)
    fields = for f <- float_fields, do: f.name

    conn
    |> put_flash(:error, "Please review and fix errors below")
    |> render("create_long_lat.html", meta: meta, fields: fields, changeset: changeset, action: action)
  end
end
