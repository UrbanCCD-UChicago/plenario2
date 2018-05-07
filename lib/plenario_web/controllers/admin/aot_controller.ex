defmodule PlenarioWeb.Admin.AotController do
  use PlenarioWeb, :admin_controller

  import Ecto.Query

  alias Plenario.Repo

  alias PlenarioAot.{AotActions, AotMeta, AotData}

  def index(conn, _) do
    render(conn, "index.html", metas: AotActions.list_metas())
  end

  def new(conn, _) do
    changeset = AotMeta.changeset()
    render(conn, "create.html", changeset: changeset)
  end

  def create(conn, %{"aot_meta" => %{"network_name" => network_name, "source_url" => source_url}}) do
    case AotActions.create_meta(network_name, source_url) do
      {:ok, meta} ->
        conn
        |> put_flash(:success, "Created new Network #{meta.network_name}")
        |> redirect(to: aot_path(conn, :index))

      {:error, changeset} ->
        conn
        |> put_flash(:error, "Please review errors below")
        |> put_status(:bad_request)
        |> render("create.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    {id, _} = Integer.parse(id)
    meta = AotActions.get_meta(id)

    count_observations =
      AotData
      |> select(fragment("count(*)"))
      |> where([d], fragment("? >= current_date - interval '24' hour", d.timestamp))
      |> where([d], d.aot_meta_id == ^meta.id)
      |> Repo.one()

    node_locations_data =
      AotData
      |> select([:latitude, :longitude, :human_address, :node_id])
      |> distinct([:latitude, :longitude])
      |> where([d], fragment("? >= current_date - interval '24' hour", d.timestamp))
      |> where([d], d.aot_meta_id == ^meta.id)
      |> Repo.all()
      |> Enum.map(fn row ->
        {
          "[#{row.latitude}, #{row.longitude}]",
          String.trim(row.human_address),
          row.node_id
        }
      end)

    render(conn, "show.html",
      meta: meta, count_observations: count_observations,
      nodes: node_locations_data)
  end

  def edit(conn, %{"id" => id}) do
    {id, _} = Integer.parse(id)
    meta = AotActions.get_meta(id)
    changeset = AotMeta.changeset(meta)
    render(conn, "edit.html", meta: meta, changeset: changeset)
  end

  def update(conn, %{"id" => id, "aot_meta" => params}) do
    {id, _} = Integer.parse(id)
    meta = AotActions.get_meta(id)
    params = Enum.into(params, [])
    case AotActions.update_meta(meta, params) do
      {:ok, meta} ->
        conn
        |> put_flash(:success, "Updated Network #{meta.network_name}")
        |> redirect(to: aot_path(conn, :index))

      {:error, changeset} ->
        conn
        |> put_flash(:error, "Please review errors below")
        |> put_status(:bad_request)
        |> render("edit.html", meta: meta, changeset: changeset)
    end
  end
end
