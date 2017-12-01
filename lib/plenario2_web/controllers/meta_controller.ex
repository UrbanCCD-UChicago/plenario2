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

  def get_update_name(conn, %{"slug" => slug}) do
    meta = MetaActions.get_from_slug(slug, [with_user: true])
    user = Guardian.Plug.current_resource(conn)

    if user.id != meta.user.id do
      conn
      |> send_resp(401, "unauthorized")
      |> halt()
    else
      changeset = MetaChangesets.update_name(meta, %{})
      action = meta_path(conn, :do_update_name, slug)
      render(conn, "update_name.html", changeset: changeset, action: action)
    end
  end

  def do_update_name(conn, %{"slug" => slug, "meta" => %{"name" => name}}) do
    meta = MetaActions.get_from_slug(slug, [with_user: true])
    user = Guardian.Plug.current_resource(conn)

    if user.id != meta.user.id do
      conn
      |> send_resp(401, "unauthorized")
      |> halt()
    else
      MetaActions.update_name(meta, name)
      |> update_name_reply(conn, meta)
    end
  end

  defp update_name_reply({:error, changeset}, conn, meta) do
    action = meta_path(conn, :do_update_name, meta.slug)
    conn
    |> put_flash(:error, "Please view and fix errors below.")
    |> render("update_name.html", changeset: changeset, action: action)
  end

  defp update_name_reply({:ok, meta}, conn, _) do
    conn
    |> put_flash(:success, "Updated name")
    |> redirect(to: meta_path(conn, :detail, meta.slug))
  end

  def get_update_description(conn, %{"slug" => slug}) do
    meta = MetaActions.get_from_slug(slug, [with_user: true])
    user = Guardian.Plug.current_resource(conn)

    if user.id != meta.user.id do
      conn
      |> send_resp(401, "unauthorized")
      |> halt()
    else
      changeset = MetaChangesets.update_description_info(meta, %{})
      action = meta_path(conn, :do_update_description, slug)
      render(conn, "update_description.html", changeset: changeset, action: action, meta: meta)
    end
  end

  def do_update_description(conn, %{"slug" => slug, "meta" => %{"description" => description, "attribution" => attribution}}) do
    meta = MetaActions.get_from_slug(slug, [with_user: true])
    user = Guardian.Plug.current_resource(conn)

    if user.id != meta.user.id do
      conn
      |> send_resp(401, "unauthorized")
      |> halt()
    else
      MetaActions.update_description_info(meta, [description: description, attribution: attribution])
      |> update_description_reply(conn, meta)
    end
  end

  defp update_description_reply({:error, changeset}, conn, meta) do
    action = meta_path(conn, :do_update_description, meta.slug)
    conn
    |> put_flash(:error, "Please view and fix errors below.")
    |> render("update_description.html", changeset: changeset, action: action)
  end

  defp update_description_reply({:ok, meta}, conn, _) do
    conn
    |> put_flash(:success, "Updated description information")
    |> redirect(to: meta_path(conn, :detail, meta.slug))
  end

  def get_update_source_info(conn, %{"slug" => slug}) do
    meta = MetaActions.get_from_slug(slug, [with_user: true])
    user = Guardian.Plug.current_resource(conn)

    if user.id != meta.user.id do
      conn
      |> send_resp(401, "unauthorized")
      |> halt()
    else
      changeset = MetaChangesets.update_source_info(meta, %{})
      action = meta_path(conn, :do_update_source_info, slug)
      render(conn, "update_source_info.html", changeset: changeset, action: action)
    end
  end

  def do_update_source_info(conn, %{"slug" => slug, "meta" => %{"source_url" => source_url, "source_type" => source_type}}) do
    meta = MetaActions.get_from_slug(slug, [with_user: true])
    user = Guardian.Plug.current_resource(conn)

    if user.id != meta.user.id do
      conn
      |> send_resp(401, "unauthorized")
      |> halt()
    else
      MetaActions.update_source_info(meta, [source_url: source_url, source_type: source_type])
      |> update_source_info_reply(conn, meta)
    end
  end

  defp update_source_info_reply({:error, changeset}, conn, meta) do
    action = meta_path(conn, :do_update_source_info, meta.slug)
    conn
    |> put_flash(:error, "Please view and fix errors below.")
    |> render("update_source_info.html", changeset: changeset, action: action)
  end

  defp update_source_info_reply({:ok, meta}, conn, _) do
    conn
    |> put_flash(:success, "Updated source information")
    |> redirect(to: meta_path(conn, :detail, meta.slug))
  end

  def get_update_refresh_info(conn, %{"slug" => slug}) do
    meta = MetaActions.get_from_slug(slug, [with_user: true])
    user = Guardian.Plug.current_resource(conn)

    if user.id != meta.user.id do
      conn
      |> send_resp(401, "unauthorized")
      |> halt()
    else
      changeset = MetaChangesets.update_refresh_info(meta, %{})
      action = meta_path(conn, :do_update_refresh_info, slug)
      render(conn, "update_refresh_info.html", changeset: changeset, action: action)
    end
  end

  def do_update_refresh_info(conn, %{"slug" => slug, "meta" => %{"refresh_rate" => refresh_rate, "refresh_interval" => refresh_interval, "refresh_starts_on" => refresh_starts_on, "refresh_ends_on" => refresh_ends_on}}) do
    meta = MetaActions.get_from_slug(slug, [with_user: true])
    user = Guardian.Plug.current_resource(conn)

    if user.id != meta.user.id do
      conn
      |> send_resp(401, "unauthorized")
      |> halt()
    else
      MetaActions.update_refresh_info(meta, [refresh_rate: refresh_rate, refresh_interval: refresh_interval, refresh_starts_on: refresh_starts_on, refresh_ends_on: refresh_ends_on])
      |> update_refresh_info_reply(conn, meta)
    end
  end

  defp update_refresh_info_reply({:error, changeset}, conn, meta) do
    action = meta_path(conn, :do_update_refresh_info, meta.slug)
    conn
    |> put_flash(:error, "Please view and fix errors below.")
    |> render("update_refresh_info.html", changeset: changeset, action: action)
  end

  defp update_refresh_info_reply({:ok, meta}, conn, _) do
    conn
    |> put_flash(:success, "Updated refresh information")
    |> redirect(to: meta_path(conn, :detail, meta.slug))
  end
end
