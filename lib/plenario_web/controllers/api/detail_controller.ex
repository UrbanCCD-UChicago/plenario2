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
      validate_slug_get_meta: 1,
      validate_slug_get_meta: 2
    ]

  alias Plenario.{
    ModelRegistry,
    Repo
  }

  alias Plenario.Schemas.Meta

  plug(:check_page_size)
  plug(:check_page)
  plug(:check_order_by, default_order: "asc:row_id")
  plug(:check_format)
  plug :check_group_by, "Before group by" when action in [:aggregate]
  plug(:check_filters)

  @spec get(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def get(conn, %{"slug" => slug}) do
    validate_slug_get_meta(slug)
    |> render_data_set(conn, "get.json")
  end

  @spec head(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def head(conn, %{"slug" => slug}) do
    validate_slug_get_meta(slug)
    |> render_data_set(conn, "head.json")
  end

  def describe(conn, %{"slug" => slug}) do
    meta =
      validate_slug_get_meta(
        slug,
        with_user: true,
        with_fields: true,
        with_virtual_dates: true,
        with_virtual_points: true
      )

    render_detail(conn, "describe.json", [meta])
  end

  # We need to halt if the meta is not found
  # We need to halt if the meta is not ready
  # Are we able to paginate?
  # We need to apply filters
  def aggregate(conn, %{"slug" => slug}) do
    meta = validate_slug_get_meta(slug)
    model = ModelRegistry.lookup(meta.slug)

    page = conn.assigns[:page]
    page_size = conn.assigns[:page_size]
    timestamp = conn.assigns[:group_by]

    data = 
      buckets(model, timestamp, "month") 
      |> Repo.all()
      |> Enum.map(&bucket_fmt/1)

    Phoenix.Controller.render(conn, "get.json", data: data)
  end

  @doc """
  Executing this query returns a list of tuples. The first element of the 
  tuple is the count for a time bucket. The second element of the tuple is 
  the time bucket.
  """
  def buckets(model, timestamp, interval) do
    from m in model,
      select: {
        count(m.row_id), 
        fragment("date_trunc(?, ?) as interval", 
          ^interval, field(m, ^timestamp))},
      group_by: fragment("interval"),
      order_by: fragment("interval")
  end

  @doc """
  Used to create a map from the output of a bucketing query.
  """
  def bucket_fmt({count, {{y, m, d}, {hh, mm, ss, _}}}) do
    %{
      count: count,
      bucket: NaiveDateTime.from_erl!({{y, m, d}, {hh, mm, ss}})
    }
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

    # We need to get rid of this. 
    #
    # For example, I was trying to figure out why I was getting a 
    # {error: null}. I kept trying different combos of query params.
    # In the end it was because I hadn't migrated my database.
    # 
    # Error handling like jumbles together user facing errors and
    # true errors for us developers. They need to be separate.
    try do
      page = conn.assigns[:page]
      page_size = conn.assigns[:page_size]
      data = Repo.paginate(query, page_number: page, page_size: page_size)
      render_detail(conn, view, data)
    rescue
      e in [Ecto.QueryError, Ecto.SubQueryError, Postgrex.Error] ->
        halt_with(conn, :bad_request, e.message)
    end
  end

  defp render_data_set(_, conn, _), do: halt_with(conn, :not_found)
end
