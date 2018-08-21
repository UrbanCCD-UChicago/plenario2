defmodule PlenarioWeb.Api.ListController do
  @moduledoc """
  """

  use PlenarioWeb, :api_controller

  import Ecto.Query

  import PlenarioWeb.Api.Plugs

  import PlenarioWeb.Api.Utils,
    only: [
      apply_filter: 4,
      halt_with: 3,
      render_list: 3
    ]

  alias Plenario.Repo

  alias Plenario.Schemas.Meta

  plug(:check_page_size)
  plug(:check_page)
  plug(:check_order_by, default_order: "asc:name")
  plug(:check_filters)
  plug(:check_format)

  @spec get(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def get(conn, _params), do: render_metas(conn, "get.json")

  @spec head(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def head(conn, _params), do: render_metas(conn, "head.json")

  defp render_metas(conn, view) do
    {dir, fname} = conn.assigns[:order_by]

    query =
      Meta
      |> where([q], q.state == ^"ready")
      |> order_by([q], {^dir, ^fname})
      |> preload(user: :metas, fields: :meta, virtual_dates: :meta, virtual_points: :meta)

    query =
      conn.assigns[:filters]
      |> Enum.reduce(query, fn {fname, op, value}, query ->
        apply_filter(query, fname, op, value)
      end)

    try do
      page = conn.assigns[:page]
      page_size = conn.assigns[:page_size]
      data = Repo.paginate(query, page_number: page, page_size: page_size)
      render_list(conn, view, data)
    rescue
      e in [Ecto.QueryError, Ecto.SubQueryError, Postgrex.Error] ->
        halt_with(conn, :bad_request, e.message)
    end
  end
end
