defmodule PlenarioWeb.Api.Utils do
  import Ecto.Query

  import Geo.PostGIS

  import Geo.PostGIS,
    only: [
      st_intersects: 2,
      st_within: 2
    ]

  import Plenario.Queries.Utils,
    only: [
      timestamp_within: 2,
      tsrange_contains_timestamp: 2,
      tsrange_intersects: 2
    ]

  import PlenarioWeb.Router.Helpers,
    only: [
      detail_url: 4,
      list_url: 3,
      aot_url: 3
    ]

  import Plug.Conn,
    only: [
      put_resp_header: 3,
      resp: 3,
      halt: 1
    ]

  import Plug.Conn.Status,
    only: [
      code: 1,
      reason_phrase: 1
    ]

  alias Geo.Polygon

  alias Plenario.TsRange

  alias Plenario.Actions.MetaActions

  alias Scrivener.Page

  # RENDERING UTILS

  @spec render_detail(Plug.Conn.t(), String.t(), Scrivener.Page.t() | Plenario.Schemas.Meta.t()) ::
          Plug.Conn.t()
  def render_detail(conn, view, page) do
    links = make_links(:detail, view, conn, page)
    counts = make_counts(view, page)
    params = fmt_params(conn)
    data = get_data(view, page)

    Phoenix.Controller.render(
      conn,
      view,
      links: links,
      counts: counts,
      params: params,
      data: data
    )
  end

  @spec render_list(Plug.Conn.t(), String.t(), Scrivener.Page.t()) :: Plug.Conn.t()
  def render_list(conn, view, page) do
    links = make_links(:list, view, conn, page)
    counts = make_counts(view, page)
    params = fmt_params(conn)
    data = get_data(view, page)

    Phoenix.Controller.render(
      conn,
      view,
      links: links,
      counts: counts,
      params: params,
      data: data
    )
  end

  @spec render_aot(Scrivener.Page.t(), Plug.Conn.t(), String.t()) :: Plug.Conn.t()
  def render_aot(page, conn, view) do
    links = make_links(:aot, view, conn, page)
    counts = make_counts(view, page)
    params = fmt_params(conn)

    data =
      case view do
        "describe.json" ->
          get_data(view, page.entries)
          |> Enum.map(
            &Map.put(&1, :fields, [
              %{
                name: "node_id",
                type: "text"
              },
              %{
                name: "human_address",
                type: "text"
              },
              %{
                name: "latitude",
                type: "float"
              },
              %{
                name: "longitude",
                type: "float"
              },
              %{
                name: "timestamp",
                type: "timestamp"
              },
              %{
                name: "observations",
                type: "object"
              },
              %{
                name: "location",
                type: "geometry(point, 4326)"
              }
            ])
          )

        _ ->
          get_data(view, page)
      end

    Phoenix.Controller.render(
      conn,
      view,
      links: links,
      counts: counts,
      params: params,
      data: data
    )
  end

  defp make_links(controller, view, conn, page) do
    {prev_page_number, next_page_number} = get_prev_next_page_numbers(page)

    prev_url =
      case view do
        "get.json" ->
          make_url(controller, :get, conn, prev_page_number)

        _ ->
          nil
      end

    next_url =
      case view do
        "get.json" ->
          make_url(controller, :get, conn, next_page_number)

        _ ->
          nil
      end

    curr_url =
      case view do
        "get.json" ->
          make_url(controller, :get, conn, page.page_number)

        "head.json" ->
          make_url(controller, :head, conn, 1)

        "describe.json" ->
          make_url(controller, :describe, conn, 1)
      end

    %{
      previous: prev_url,
      current: curr_url,
      next: next_url
    }
  end

  defp make_counts(view, page) do
    case view do
      "describe.json" ->
        %{
          data_count: 1,
          total_pages: 1,
          total_records: 1
        }

      _ ->
        %{
          data_count: length(page.entries),
          total_pages: page.total_pages,
          total_records: page.total_entries
        }
    end
  end

  defp get_data(view, page) do
    case view do
      "describe.json" ->
        page

      _ ->
        page.entries
    end
  end

  defp get_prev_next_page_numbers(%Page{total_pages: last, page_number: current}) do
    previous = if current == 1, do: nil, else: current - 1
    next = if current == last, do: nil, else: current + 1

    {previous, next}
  end

  defp get_prev_next_page_numbers(_), do: {nil, nil}

  defp make_url(:detail, _, _, nil), do: nil

  defp make_url(:detail, fun_atom, conn, page_number) do
    params = Map.merge(conn.params, %{"page" => page_number})
    slug = Map.get(conn.params, "slug")
    detail_url(conn, fun_atom, slug, params)
  end

  defp make_url(:list, _, _, nil), do: nil

  defp make_url(:list, fun_atom, conn, page_number) do
    params = Map.merge(conn.params, %{"page" => page_number})
    list_url(conn, fun_atom, params)
  end

  defp make_url(:aot, _, _, nil), do: nil

  defp make_url(:aot, fun_atom, conn, page_number) do
    params = Map.merge(conn.params, %{"page" => page_number})
    aot_url(conn, fun_atom, params)
  end

  defp fmt_params(conn) do
    page = conn.assigns[:page]
    size = conn.assigns[:page_size]
    {dir, field} = conn.assigns[:order_by]

    params = %{
      page: page,
      page_size: size,
      order_by: %{
        dir => field
      }
    }

    params =
      conn.assigns[:filters]
      |> Enum.reduce(params, fn {field, op, value}, params ->
        Map.put(params, field, %{op => value})
      end)

    params =
      case conn.assigns[:window] do
        nil ->
          params

        w ->
          Map.put(params, :window, w)
      end

    params
  end

  # HALT

  @spec halt_with(Plug.Conn.t(), atom() | integer()) :: Plug.Conn.t()
  def halt_with(conn, status) do
    status_code = code(status)
    message = reason_phrase(status_code)

    do_halt_with(conn, status_code, message)
  end

  @spec halt_with(Plug.Conn.t(), atom() | integer(), String.t()) :: Plug.Conn.t()
  def halt_with(conn, status, message) do
    status_code = code(status)
    do_halt_with(conn, status_code, message)
  end

  defp do_halt_with(conn, code, message) do
    body =
      %{error: message}
      |> Poison.encode!()

    conn
    |> put_resp_header("content-type", "application/json")
    |> resp(code, body)
    |> halt()
  end

  # CONTROLLER HELPERS -- FETCHING, VALIDATING, QUERYING

  @spec validate_data_set(String.t()) :: Plenario.Schemas.Meta.t() | :error | nil
  def validate_data_set(slug), do: validate_data_set(slug, [])

  @spec validate_data_set(String.t(), Keyword.t()) :: Plenario.Schemas.Meta.t() | :error | nil
  def validate_data_set(slug, opts) when is_bitstring(slug) do
    case Regex.match?(~r/^\d+$/, slug) do
      true ->
        nil

      false ->
        MetaActions.get(slug, opts)
    end
  end

  def validate_data_set(_, _), do: :error

  @spec apply_filter(Ecto.Queryable.t(), String.t(), String.t(), any()) :: Ecto.Queryable.t()
  def apply_filter(query, fname, "lt", value), do: where(query, [q], field(q, ^fname) < ^value)

  def apply_filter(query, fname, "le", value), do: where(query, [q], field(q, ^fname) <= ^value)

  def apply_filter(query, fname, "eq", value), do: where(query, [q], field(q, ^fname) == ^value)

  def apply_filter(query, fname, "ge", value), do: where(query, [q], field(q, ^fname) >= ^value)

  def apply_filter(query, fname, "gt", value), do: where(query, [q], field(q, ^fname) > ^value)

  def apply_filter(query, fname, "in", value), do: where(query, [q], field(q, ^fname) in ^value)

  def apply_filter(query, fname, "within", %TsRange{} = value),
    do: where(query, [q], timestamp_within(field(q, ^fname), ^TsRange.to_postgrex(value)))

  def apply_filter(query, fname, "within", %Polygon{} = value),
    do: where(query, [q], st_within(field(q, ^fname), ^value))

  def apply_filter(query, fname, "intersects", %TsRange{} = value),
    do: where(query, [q], tsrange_intersects(field(q, ^fname), ^TsRange.to_postgrex(value)))

  def apply_filter(query, fname, "intersects", %Polygon{} = value),
    do: where(query, [q], st_intersects(field(q, ^fname), ^value))

  def apply_filter(query, fname, "contains", %NaiveDateTime{} = value),
    do: where(query, [q], tsrange_contains_timestamp(field(q, ^fname), ^value))
end
