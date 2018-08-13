defmodule PlenarioWeb.Api.ShimController do
  @moduledoc """
  """

  use PlenarioWeb, :api_controller

  import Ecto.Query

  import PlenarioWeb.Api.Plugs

  import PlenarioWeb.Api.Utils,
    only: [
      apply_filter: 4,
      halt_with: 2,
      halt_with: 3
    ]

  alias Plenario.{
    ModelRegistry,
    Repo
  }

  alias Plenario.Actions.MetaActions

  alias Plenario.Schemas.Meta

  # SHIM SPECIFIC PLUGS

  defp check_dataset_name(conn, _opts) do
    case Map.get(conn.params, "dataset_name") do
      nil ->
        conn

      name ->
        slug = String.replace(name, "_", "-")
        assign(conn, :slug, {:slug, "eq", slug})
    end
  end

  defp check_obs_date(conn, _opts) do
    obs_date = Map.get(conn.params, "obs_date__ge")

    obs_date =
      case Map.get(conn.params, "obs_date__le") do
        nil ->
          obs_date

        value ->
          value
      end

    case obs_date do
      nil ->
        conn

      value ->
        case Timex.parse(value, "%Y-%m-%d", :strftime) do
          {:ok, date} ->
            assign(conn, :obs_date, {:time_range, "contains", date})

          _ ->
            halt_with(conn, :bad_request, "Could not parse observation date")
        end
    end
  end

  defp check_location_geom(conn, _opts) do
    case Map.get(conn.params, "location_geom__within") do
      nil ->
        conn

      value ->
        try do
          geom =
            Poison.decode!(value)
            |> Geo.JSON.decode()

          assign(conn, :geom, {:bbox, "intersects", geom})
        rescue
          _ ->
            halt_with(conn, :bad_request, "Could not parse bounding box")
        end
    end
  end

  plug(:check_page)
  plug(:check_page_size)
  plug(:check_order_by, default_order: "asc:name")
  plug(:check_dataset_name)
  plug(:check_obs_date)
  plug(:check_location_geom)

  # CONTROLLERS

  @spec datasets(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def datasets(conn, _params) do
    {dir, fname} = conn.assigns[:order_by]

    query =
      Meta
      |> where([m], m.state == ^"ready")
      |> order_by([m], [{^dir, ^fname}])
      |> preload(fields: :meta, virtual_dates: :meta, virtual_points: :meta)

    query =
      [conn.assigns[:slug], conn.assigns[:obs_date], conn.assigns[:geom]]
      |> Enum.reject(&is_nil/1)
      |> Enum.reduce(query, fn {fname, op, value}, query ->
        apply_filter(query, fname, op, value)
      end)

    try do
      page = conn.assigns[:page]
      page_size = conn.assigns[:page_size]
      data = Repo.paginate(query, page: page, page_size: page_size)
      render(conn, "datasets.json", data: data)
    rescue
      e in [Ecto.QueryError, Ecto.SubQueryError, Postgrex.Error] ->
        halt_with(conn, :bad_request, e.message)
    end
  end

  @spec fields(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def fields(conn, %{"slug" => slug}) do
    slug =
      slug
      |> String.replace("_", "-")

    MetaActions.get(slug, with_fields: true, with_virtual_dates: true, with_virtual_points: true)
    |> do_fields(conn)
  end

  defp do_fields(%Meta{state: "ready"} = meta, conn), do: render(conn, "fields.json", meta: meta)

  defp do_fields(_, conn), do: halt_with(conn, :not_found)

  @spec detail(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def detail(conn, %{"dataset_name" => _}) do
    {_, _, slug} = conn.assigns[:slug]

    MetaActions.get(slug)
    |> render_data_set(conn)
  end

  def detail(conn, _params), do: halt_with(conn, :not_found)

  defp render_data_set(%Meta{state: "ready"} = meta, conn) do
    model = ModelRegistry.lookup(meta.slug)

    query =
      model
      |> order_by([q], asc: q.row_id)

    try do
      page = conn.assigns[:page]
      page_size = conn.assigns[:page_size]
      data = Repo.paginate(query, page: page, page_size: page_size)
      render(conn, "detail.json", data: data.entries)
    rescue
      e in [Ecto.QueryError, Ecto.SubQueryError, Postgrex.Error] ->
        IO.inspect(e)
        halt_with(conn, :bad_request, e.message)
    end
  end

  defp render_data_set(_, conn), do: halt_with(conn, :not_found)
end
