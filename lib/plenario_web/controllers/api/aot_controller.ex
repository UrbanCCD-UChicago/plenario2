defmodule PlenarioWeb.Api.AotController do
  @moduledoc """
  """

  use PlenarioWeb, :api_controller

  import Ecto.Query

  import PlenarioWeb.Api.Plugs

  import PlenarioWeb.Api.Utils,
    only: [
      apply_filter: 4,
      halt_with: 3,
      render_aot: 3
    ]

  alias Plenario.Repo

  alias PlenarioAot.{
    AotData,
    AotMeta
  }

  plug(:check_page)
  plug(:check_page_size)
  plug(:check_order_by, default_order: "desc:timestamp")
  plug(:check_filters)
  plug(:apply_window)

  @meta_keys [:network_name, :bbox, :time_rage]

  @spec get(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def get(conn, _params) do
    get_meta_ids(conn)
    |> get_data(conn)
    |> render_data(conn, "get.json")
  end

  @spec head(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def head(conn, _params) do
    get_meta_ids(conn)
    |> get_data(conn)
    |> render_data(conn, "head.json")
  end

  @spec describe(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def describe(conn, _params) do
    page = conn.assigns[:page]
    page_size = conn.assigns[:page_size]

    conn.assigns[:filters]
    |> Enum.filter(fn {fname, _, _} -> fname in @meta_keys end)
    |> Enum.reduce(AotMeta, fn {fname, op, value}, query ->
      apply_filter(query, fname, op, value)
    end)
    |> Repo.paginate(page: page, page_size: page_size)
    |> render_aot(conn, "describe.json")
  end

  defp get_meta_ids(conn) do
    query =
      conn.assigns[:filters]
      |> Enum.filter(fn {fname, _, _} -> fname in @meta_keys end)
      |> Enum.reduce(AotMeta, fn {fname, op, value}, query ->
        apply_filter(query, fname, op, value)
      end)
      |> select([q], q.id)
      |> distinct([q], q.id)

    try do
      ids = Repo.all(query)
      {:ok, ids}
    rescue
      e in [Ecto.QueryError, Ecto.SubQueryError, Postgrex.Error] ->
        {:error, e.message}
    end
  end

  defp get_data({:error, message}, _), do: {:error, message}

  defp get_data({:ok, meta_ids}, conn) do
    query =
      conn.assigns[:filters]
      |> Enum.reject(fn {fname, _, _} -> fname in @meta_keys end)
      |> Enum.reduce(AotData, fn {fname, op, value}, query ->
        apply_filter(query, fname, op, value)
      end)
      |> where([q], q.aot_meta_id in ^meta_ids)
      |> where([q], q.updated_at <= ^conn.assigns[:window])
      |> join(:left, [d], m in assoc(d, :aot_meta))
      |> select([d, m], %{d | aot_meta: %{network_name: m.network_name, slug: m.slug}})

    try do
      page = conn.assigns[:page]
      page_size = conn.assigns[:page_size]
      data = Repo.paginate(query, page: page, page_size: page_size)
      {:ok, data}
    rescue
      e in [Ecto.QueryError, Ecto.SubQueryError, Postgrex.Error] ->
        {:error, e.message}
    end
  end

  defp render_data({:error, message}, conn, _), do: halt_with(conn, :bad_request, message)

  defp render_data({:ok, data}, conn, view), do: render_aot(data, conn, view)
end
