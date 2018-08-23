defmodule PlenarioWeb.Api.DetailController do
  @moduledoc """
  """

  use PlenarioWeb, :api_controller

  import Ecto.Query

  import PlenarioWeb.Api.Plugs

  import PlenarioWeb.Api.Utils,
    only: [
      apply_filter: 4,
      halt_with: 2,
      halt_with: 3,
      render_detail: 3,
      validate_data_set: 1,
      validate_data_set: 2
    ]

  alias Plenario.{
    ModelRegistry,
    Repo
  }

  alias Plenario.Schemas.Meta

  plug(:check_page_size)
  plug(:check_page)
  plug(:check_order_by, default_order: "asc:row_id")
  plug(:check_filters)
  # todo need this
  # plug(:check_group_by)

  @spec get(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def get(conn, %{"slug" => slug}) do
    validate_data_set(slug)
    |> render_data_set(conn, "get.json")
  end

  @spec head(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def head(conn, %{"slug" => slug}) do
    validate_data_set(slug)
    |> render_data_set(conn, "head.json")
  end

  def describe(conn, %{"slug" => slug}) do
    meta =
      validate_data_set(
        slug,
        with_user: true,
        with_fields: true,
        with_virtual_dates: true,
        with_virtual_points: true
      )

    render_detail(conn, "describe.json", meta)
  end

  def aggregate(conn, %{"slug" => slug}) do
    validate_data_set(slug)
    |> render_data_set_aggregate(conn, "get.json")
  end

  defp render_data_set(%Meta{state: "ready"} = meta, conn, view) do
    model = ModelRegistry.lookup(meta.slug)

    {dir, fname} = conn.assigns[:order_by]

    query =
      model
      |> order_by([q], [{^dir, ^fname}])

    query =
      conn.assigns[:filters]
      |> Enum.reduce(query, fn {fname, op, value}, query ->
        apply_filter(query, fname, op, value)
      end)

    try do
      page = conn.assigns[:page]
      page_size = conn.assigns[:page_size]
      data = Repo.paginate(query, page: page, page_size: page_size)
      render_detail(conn, view, data)
    rescue
      e in [Ecto.QueryError, Ecto.SubQueryError, Postgrex.Error] ->
        halt_with(conn, :bad_request, e.message)
    end
  end

  defp render_data_set(_, conn, _), do: halt_with(conn, :not_found)

  defp render_data_set_aggregate(%Meta{state: "ready"} = meta, conn, view) do
    model = ModelRegistry.lookup(meta.slug)

    page = conn.assigns[:page]
    page_size = conn.assigns[:page_size]
    group_by_field = conn.params["group_by"] |> String.to_atom()

    # order ∈ {:asc, :desc}
    {order, order_by} = conn.assigns[:order_by]


    # query =
    #   conn.assigns[:filters]
    #   |> Enum.reduce(fn {field, operation, value}, query ->
    #     apply_filter(query, field, operation, value)
    #   end)

    # try do
      # data = Repo.paginate(query, page: page, page_size: page_size)
      # Need to discern significant column here, read in as user arg
      data = from(model) |> group_by([p], fragment("date_part('month', ?)", field(p, ^group_by_field))) |> select([p], count("*")) |> Repo.all
      IO.inspect(data)
      render_detail(conn, view, data)
    # rescue
    #   e in [Ecto.QueryError, Ecto.SubQueryError, Postgrex.Error] ->
    #     halt_with(conn, :bad_request, e.message)
    # end
  end

  defp render_data_set_aggregate(_, conn, _), do: halt_with(conn, :not_found)
end
