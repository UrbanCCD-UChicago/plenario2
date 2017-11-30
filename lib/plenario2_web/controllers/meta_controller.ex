defmodule Plenario2Web.MetaController do
  use Plenario2Web, :controller
  alias Plenario2.Actions.MetaActions
  alias Plenario2.Changesets.MetaChangesets
  alias Plenario2.Schemas.Meta
  alias Plenario2Web.ErrorView

  def detail(conn, %{"slug" => slug}) do
    user = Guardian.Plug.current_resource(conn)
    meta = MetaActions.get_from_slug(slug, [with_user: true, with_fields: true])
    owner = user.email_address == meta.user.email_address
    case meta do
      nil  -> conn |> put_status(:not_found) |> put_view(ErrorView) |> render("404.html")
      _    -> render(conn, "detail.html", meta: meta, owner: owner)
    end
  end

  def list(conn, _params) do
    metas = MetaActions.list([with_user: true])
    render(conn, "list.html", metas: metas)
  end

  def get_create(conn, _params) do
    changeset = MetaChangesets.create(%Meta{}, %{})
    action = meta_path(conn, :do_create)

    render(conn, "create.html", changeset: changeset, action: action)
  end

  def do_create(conn, %{"meta" => %{"name" => name, "source_url" => source_url}} = params) do
    user = Guardian.Plug.current_resource(conn)
    details = Enum.map([
        "source_type",
        "description",
        "attribution",
        "refresh_rate",
        "refresh_interval",
        "refresh_starts_on",
        "refresh_ends_on",
        "srid",
        "timezone"
      ],
      fn (key) -> {String.to_atom(key), Map.get(params["meta"], key, nil)} end)
    |> Enum.filter(fn ({k, v}) -> if v do {k, v} end end)

    MetaActions.create(name, user.id, source_url, details)
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
