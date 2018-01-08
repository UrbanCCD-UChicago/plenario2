defmodule Plenario2Web.DataSetConstraintController do
  use Plenario2Web, :controller

  alias Plenario2.Actions.{MetaActions, DataSetConstraintActions}
  alias Plenario2.Changesets.DataSetConstraintChangesets

  def get_create(conn, %{"slug" => meta_slug}) do
    meta = MetaActions.get(meta_slug, [with_fields: true])
    changeset = DataSetConstraintChangesets.new()
    action = data_set_constraint_path(conn, :do_create, meta_slug)

    field_opts = for f <- meta.data_set_fields, do: [{:key, "#{f.name} (#{f.type})"}, {:value, f.name}]

    render(conn, "create.html", meta: meta, changeset: changeset, action: action, field_opts: field_opts)
  end

  def do_create(conn, %{"slug" => meta_slug, "data_set_constraint" => params}) do
    DataSetConstraintActions.create(params["meta_id"], params["field_names"])
    |> create_reply(conn, meta_slug)
  end

  defp create_reply({:ok, _}, conn, meta_slug) do
    conn
    |> put_flash(:success, "Constraint Created")
    |> redirect(to: meta_path(conn, :detail, meta_slug))
  end

  defp create_reply({:error, changeset}, conn, meta_slug) do
    meta = MetaActions.get(meta_slug, [with_fields: true])
    action = data_set_constraint_path(conn, :do_create, meta_slug)

    field_opts = for f <- meta.data_set_fields, do: [{String.to_atom("#{f.name} (#{f.type})"), f.name}]

    conn
    |> put_flash(:error, "Please review and fix errors below")
    |> render("create.html", meta: meta, changeset: changeset, action: action, field_opts: field_opts)
  end
end
