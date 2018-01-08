defmodule Plenario2Web.VirtualDateFieldController do
  use Plenario2Web, :controller

  alias Plenario2.Actions.{MetaActions, VirtualDateFieldActions}
  alias Plenario2.Changesets.VirtualDateFieldChangesets

  def get_create(conn, %{"slug" => meta_slug}) do
    meta = MetaActions.get(meta_slug, [with_fields: true])
    changeset = VirtualDateFieldChangesets.new()
    action = virtual_date_field_path(conn, :do_create, meta_slug)

    integer_fields = Enum.filter(meta.data_set_fields, fn f -> f.type == "integer" end)
    fields = [""] ++ for f <- integer_fields, do: f.name

    render(conn, "create.html", meta: meta, fields: fields, changeset: changeset, action: action)
  end

  def do_create(conn, %{"slug" => meta_slug, "virtual_date_field" => params}) do
    VirtualDateFieldActions.create(
      params["meta_id"],
      params["year_field"],
      params["month_field"],
      params["day_field"],
      params["hour_field"],
      params["minute_field"],
      params["second_field"]
    )
    |> create_reply(conn, meta_slug)
  end

  defp create_reply({:ok, _}, conn, meta_slug) do
    conn
    |> put_flash(:success, "Date Field Created")
    |> redirect(to: meta_path(conn, :detail, meta_slug))
  end

  defp create_reply({:error, changeset}, conn, meta_slug) do
    meta = MetaActions.get(meta_slug, [with_fields: true])
    action = virtual_date_field_path(conn, :do_create, meta_slug)

    integer_fields = Enum.filter(meta.data_set_fields, fn f -> f.type == "integer" end)
    fields = [""] ++ for f <- integer_fields, do: f.name

    conn
    |> put_flash(:error, "Please review and fix errors below")
    |> render("create.html", meta: meta, fields: fields, changeset: changeset, action: action)
  end
end
