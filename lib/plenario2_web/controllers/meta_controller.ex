defmodule Plenario2Web.MetaController do
  use Plenario2Web, :controller

  require Logger

  alias Plenario2.Actions.MetaActions
  alias Plenario2.Changesets.MetaChangesets
  alias Plenario2.Schemas.Meta
  alias Plenario2Web.ErrorView

  @meta_source_type_options [
    "CSV": "csv", 
    "TSV": "tsv",
    "JSON": "json",
    "Shapefile": "shp"
  ] 

  plug :load_and_authorize_resource,
    model: Meta,
    id_name: "slug",
    id_field: "slug",
    except: [:detail, :list, :get_create, :do_create]

  def detail(conn, %{"slug" => slug}) do
    curr_path = current_path(conn)
    user = Guardian.Plug.current_resource(conn)
    meta = MetaActions.get(
      slug, [
        with_user: true,
        with_fields: true,
        with_notes: true,
        curr_path: curr_path,
        with_virtual_points: true,
        with_virtual_dates: true,
        with_constraints: true,
    ])
    owner = case user do
      nil -> false
      _   -> user.id == meta.user.id
    end

    case meta do
      nil ->
        conn
        |> put_status(:not_found)
        |> put_view(ErrorView)
        |> render("404.html")

      _ ->
        editing_disabled =
          case meta.state == "ready" do
            true -> "disable"
            false -> false
          end
        render(conn, "detail.html", meta: meta, owner: owner, curr_path: curr_path, editing_disabled: editing_disabled)
    end
  end

  def list(conn, _params) do
    metas = MetaActions.list([with_user: true])
    render(conn, "list.html", metas: metas)
  end

  def get_create(conn, _params) do
    changeset = MetaChangesets.new()
    action = meta_path(conn, :do_create)

    render(conn, "create.html", 
      changeset: changeset, 
      action: action,
      source_type_options: @meta_source_type_options
    )
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

    Logger.info "Creating: #{inspect(params)}"

    MetaActions.create(name, user.id, source_url, details)
    |> create_reply(conn)
  end

  defp create_reply({:ok, meta}, conn) do
    Logger.info("Meta \##{meta.id} created")
    conn
    |> put_flash(:success, "#{meta.name} Created!")
    |> redirect(to: meta_path(conn, :list))
  end

  defp create_reply({:error, changeset}, conn) do
    action = meta_path(conn, :do_create)
    conn
    |> put_status(:bad_request)
    |> put_flash(:error, "Please review and fix errors below.")
    |> render("create.html", changeset: changeset, action: action, source_type_options: @meta_source_type_options)
  end

  def submit_for_approval(conn, %{"slug" => slug}) do
    meta = MetaActions.get(slug, [with_user: true])
    MetaActions.submit_for_approval(meta)

    conn
    |> put_flash(:success, "#{meta.name} Submitted for Approval!")
    |> redirect(to: meta_path(conn, :detail, meta.slug))
  end

  def ingest_dataset(conn, %{"slug" => slug}) do
    meta = MetaActions.get(slug, [with_user: true])
    Plenario2Etl.Worker.async_load!(%{meta_id: meta.id})
    Logger.info "Ingesting #{meta.id}"
    conn
    |> put_flash(:success, "#{meta.name} Ingest started!")
    |> redirect(to: meta_path(conn, :detail, meta.slug))
  end

  def get_update_name(conn, %{"slug" => slug}) do
    meta = MetaActions.get(slug, [with_user: true])
    changeset = MetaChangesets.update_name(meta, %{})
    action = meta_path(conn, :do_update_name, slug)

    render(conn, "update_name.html", changeset: changeset, action: action)
  end

  def do_update_name(conn, %{"slug" => slug, "meta" => %{"name" => name}}) do
    meta = MetaActions.get(slug, [with_user: true])
    Logger.info "Updating name: #{name}"
    MetaActions.update_name(meta, name)
    |> update_name_reply(conn, meta)
  end

  defp update_name_reply({:error, changeset}, conn, meta) do
    action = meta_path(conn, :do_update_name, meta.slug)
    conn
    |> put_flash(:error, "Please view and fix errors below.")
    |> put_status(:bad_request)
    |> render("update_name.html", changeset: changeset, action: action)
  end

  defp update_name_reply({:ok, meta}, conn, _) do
    conn
    |> put_flash(:success, "Updated name")
    |> redirect(to: meta_path(conn, :detail, meta.slug))
  end

  def get_update_description(conn, %{"slug" => slug}) do
    meta = MetaActions.get(slug, [with_user: true])
    changeset = MetaChangesets.update_description_info(meta, %{})
    action = meta_path(conn, :do_update_description, slug)

    render(conn, "update_description.html", changeset: changeset, action: action, meta: meta)
  end

  def do_update_description(conn, %{"slug" => slug, "meta" => %{"description" => description, "attribution" => attribution}}) do
    meta = MetaActions.get(slug, [with_user: true])
    Logger.info "Updating description: #{description}, attribution: #{attribution}"
    MetaActions.update_description_info(meta, [description: description, attribution: attribution])
    |> update_description_reply(conn, meta)
  end

  defp update_description_reply({:error, changeset}, conn, meta) do
    action = meta_path(conn, :do_update_description, meta.slug)
    conn
    |> put_flash(:error, "Please view and fix errors below.")
    |> put_status(:bad_request)
    |> render("update_description.html", changeset: changeset, action: action)
  end

  defp update_description_reply({:ok, meta}, conn, _) do
    conn
    |> put_flash(:success, "Updated description information")
    |> redirect(to: meta_path(conn, :detail, meta.slug))
  end

  def get_update_source_info(conn, %{"slug" => slug}) do
    meta = MetaActions.get(slug, [with_user: true])
    changeset = MetaChangesets.update_source_info(meta, %{})
    action = meta_path(conn, :do_update_source_info, slug)

    render(conn, "update_source_info.html", changeset: changeset, action: action)
  end

  def do_update_source_info(conn, %{"slug" => slug, "meta" => %{"source_url" => source_url, "source_type" => source_type}}) do
    meta = MetaActions.get(slug, [with_user: true])
    Logger.info "Updating source url: #{source_url}, source_type: #{source_type}"
    MetaActions.update_source_info(meta, [source_url: source_url, source_type: source_type])
    |> update_source_info_reply(conn, meta)
  end

  defp update_source_info_reply({:error, changeset}, conn, meta) do
    action = meta_path(conn, :do_update_source_info, meta.slug)
    conn
    |> put_flash(:error, "Please view and fix errors below.")
    |> put_status(:bad_request)
    |> render("update_source_info.html", changeset: changeset, action: action)
  end

  defp update_source_info_reply({:ok, meta}, conn, _) do
    conn
    |> put_flash(:success, "Updated source information")
    |> redirect(to: meta_path(conn, :detail, meta.slug))
  end

  def get_update_refresh_info(conn, %{"slug" => slug}) do
    meta = MetaActions.get(slug, [with_user: true])
    changeset = MetaChangesets.update_refresh_info(meta, %{})
    action = meta_path(conn, :do_update_refresh_info, slug)
    rr_choices = Meta.get_refresh_rate_choices()

    render(conn, "update_refresh_info.html", changeset: changeset, action: action, rr_choices: rr_choices)
  end

  def do_update_refresh_info(conn, %{"slug" => slug, "meta" => %{"refresh_rate" => refresh_rate, "refresh_interval" => refresh_interval, "refresh_starts_on" => refresh_starts_on, "refresh_ends_on" => refresh_ends_on}}) do
    meta = MetaActions.get(slug, [with_user: true])
    Logger.info "Updating refresh rate: #{refresh_rate}, refresh interval: #{refresh_interval}, refresh start: #{refresh_starts_on}, refresh end: #{refresh_ends_on}"
    MetaActions.update_refresh_info(meta, [refresh_rate: refresh_rate, refresh_interval: refresh_interval, refresh_starts_on: refresh_starts_on, refresh_ends_on: refresh_ends_on])
    |> update_refresh_info_reply(conn, meta)
  end

  defp update_refresh_info_reply({:error, changeset}, conn, meta) do
    action = meta_path(conn, :do_update_refresh_info, meta.slug)
    conn
    |> put_flash(:error, "Please view and fix errors below.")
    |> put_status(:bad_request)
    |> render("update_refresh_info.html", changeset: changeset, action: action)
  end

  defp update_refresh_info_reply({:ok, meta}, conn, _) do
    conn
    |> put_flash(:success, "Updated refresh information")
    |> redirect(to: meta_path(conn, :detail, meta.slug))
  end
end
