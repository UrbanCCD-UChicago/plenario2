defmodule Plenario2Web.MetaController do
  require Logger
  use Plenario2Web, :controller
  alias Plenario2.Schemas.Meta
  alias Plenario2.Actions.MetaActions
  alias Plenario2.Changesets.MetaChangesets

  def list(conn, _params) do
    metas = MetaActions.list()

    render(conn, "list.html", metas: metas)
  end

  def create(conn, _params) do
    changeset = MetaChangesets.create(%Meta{}, %{})
    action = meta_path(conn, :do_create)

    render(conn, "create.html", changeset: changeset, action: action)
  end

  def do_create(conn, %{"meta" => %{
      "name" => name,
      "source_url" => source_url,
      "source_type" => source_type,
      "description" => description,
      "attribution" => attribution,
      "refresh_rate" => refresh_rate,
      "refresh_interval" => refresh_interval,
      "refresh_starts_on" => refresh_starts_on,
      "refresh_ends_on" => refresh_ends_on,
      "srid" => srid,
      "timezone" => timezone
      }}) do
    deatils = [
      description: description,
      attribution: attribution,
      refresh_rate: refresh_rate,
      refresh_interval: refresh_interval,
      refresh_starts_on: refresh_starts_on,
      refresh_ends_on: refresh_ends_on,
      srid: srid,
      timezone: timezone
    ]
    user = Guardian.Plug.current_resource(conn)

    MetaActions.create(name, user.id, source_url, deatils)
    |> create_reply(conn)
  end

  defp create_reply({:ok, meta}, conn) do
    conn
    |> put_flash(:success, "#{meta.name} Created!")
    |> redirect(to: meta_path(conn, :list))
  end

  defp create_reply({:error, changeset}, conn) do
    action = meta_path(conn, :do_create)
    conn
    |> put_flash(:error, "Please review and fix errors below.")
    |> render("create.html", changeset: changeset, action: action)
  end
end
