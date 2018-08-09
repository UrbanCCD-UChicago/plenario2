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

  alias Plenario.{
    Repo,
    TsRange
  }

  alias Plenario.Actions.MetaActions

  alias Scrivener.Page

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

  @spec validate_data_set(String.t(), Keyword.t()) :: Plenario.Schemas.Meta.t() | :error | nil
  def validate_data_set(slug, opts \\ []) when is_bitstring(slug) do
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

  def apply_filter(query, fname, "within", %TsRange{} = value),
    do: where(query, [q], timestamp_within(field(q, ^fname), ^TsRange.to_postgrex(value)))

  def apply_filter(query, fname, "within", %Polygon{} = value),
    do: where(query, [q], st_within(field(q, ^fname), ^value))

  def apply_filter(query, fname, "intersects", %TsRange{} = value),
    do: where(query, [q], tsrange_intersects(field(q, ^fname), ^TsRange.to_postgrex(value)))

  def apply_filter(query, fname, "intersects", %Polygon{} = value),
    do: where(query, [q], st_intersects(field(q, ^fname), ^value))

  @spec render_detail(Plug.Conn.t(), String.t(), Scrivener.Page.t() | Plenario.Schemas.Meta.t()) ::
          Plug.Conn.t()
  def render_detail(conn, view, page) do
    {prev_page_number, next_page_number} = get_prev_next_page_numbers(page)

    prev_url =
      case view do
        "get.json" ->
          make_url(:detail, :get, conn, prev_page_number)

        _ ->
          nil
      end

    next_url =
      case view do
        "get.json" ->
          make_url(:detail, :get, conn, next_page_number)

        _ ->
          nil
      end

    curr_url =
      case view do
        "get.json" ->
          make_url(:detail, :get, conn, page.page_number)

        "head.json" ->
          make_url(:detail, :head, conn, 1)

        "describe.json" ->
          make_url(:detail, :describe, conn, 1)
      end

    links = %{
      previous: prev_url,
      current: curr_url,
      next: next_url
    }

    counts =
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

    params = fmt_params(conn)

    data =
      case view do
        "describe.json" ->
          page

        _ ->
          page.entries
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

    fields =
      case conn.assigns[:filters] do
        nil ->
          %{}

        _ ->
          conn.assigns[:filters]
      end

    fields
    |> Enum.reduce(params, fn {field, op, value}, params ->
      Map.put(params, field, %{op => value})
    end)
  end

  # TODO: delete or refactor everything below this

  @doc """
  Utility function for rendering a `Scrivener.Page` of results. Even if the
  controller actions that produce these pages are different, there's enough
  in common that they can share a rendering function.
  """
  def render_page(conn, view, params, entries, page, aot \\ false) do
    Phoenix.Controller.render(conn, view, %{
      links: generate_links(conn, page, aot),
      params: Map.new(params),
      data_count: length(entries),
      total_pages: page.total_pages,
      total_records: page.total_entries,
      data: entries
    })
  end

  @doc """
  Generates the url links for navigating pages in the meta["links"] part of
  the api response.
  """
  def generate_links(conn, page, aot \\ false) do
    page_number = page.page_number
    total_pages = page.total_pages
    page_size = page.page_size

    # Remove the pagination parameters so when we reconstruct the query string,
    # we don't repeat them unnecessarily.
    non_page_params =
      Enum.filter(conn.params, fn {key, _} ->
        key not in ["page", "page_size"]
      end)

    # If we're on page one, then there is no previous link
    previous_page_number = if page_number == 1, do: nil, else: page_number - 1

    # If we're on the last page, then there is no next page
    next_page_number = if page_number == total_pages, do: nil, else: page_number + 1

    # And of course
    current_page_number = page_number

    params =
      Enum.map(non_page_params, fn {k, v} ->
        if is_atom(k) do
          {k, v}
        else
          {String.to_atom(k), v}
        end
      end)

    # Construct the query strings
    previous_page_url =
      case aot do
        false -> construct_url(conn, params, page_size, previous_page_number)
        true -> construct_aot_url(conn, params, page_size, previous_page_number)
      end

    next_page_url =
      case aot do
        false -> construct_url(conn, params, page_size, next_page_number)
        true -> construct_aot_url(conn, params, page_size, next_page_number)
      end

    current_page_url =
      case aot do
        false -> construct_url(conn, params, page_size, current_page_number)
        true -> construct_aot_url(conn, params, page_size, current_page_number)
      end

    %{
      previous: previous_page_url,
      current: current_page_url,
      next: next_page_url
    }
  end

  @doc """
  Generates the url used to navigate the pages. The first head of this function
  returns nil if no page number is specified, this is just for convenience.
  """
  def construct_url(_, _, _, nil), do: nil

  def construct_url(%Plug.Conn{params: %{"slug" => slug}} = conn, params, page_size, page) do
    params_kwlist = params ++ [page_size: page_size, page: page]
    detail_url(conn, :get, slug, params_kwlist)
  end

  def construct_url(conn, params, page_size, page) do
    params_kwlist = params ++ [page_size: page_size, page: page]
    list_url(conn, :get, params_kwlist)
  end

  def construct_aot_url(conn, params, page_size, page) do
    params_kwlist = params ++ [page_size: page_size, page: page]
    aot_url(conn, :get, params_kwlist)
  end

  @doc """
  This head of the function ensures that the column is converted to an atom
  before being used in a query. Ecto does not allow you to specify a column
  with a string.
  """
  def where_condition(query, {column, condition}) when is_binary(column) do
    where_condition(query, {String.to_atom(column), condition})
  end

  @doc """
  where_condition(query, {column, {operator, operand}})

  These functions match against the `operator` and generate the appropriate
  query condition. This function can be chained to add multiple conditions.

  ## Examples

      iex> Model
      ...>   |> where_condition({"column", {"gt", 10000}})
      ...>   |> where_condition({"column", {"lt", 20000}})

  """
  def where_condition(query, {column, {"gt", value}}),
    do: from(q in query, where: field(q, ^column) > ^value)

  def where_condition(query, {column, {"ge", value}}),
    do: from(q in query, where: field(q, ^column) >= ^value)

  def where_condition(query, {column, {"lt", value}}),
    do: from(q in query, where: field(q, ^column) < ^value)

  def where_condition(query, {column, {"le", value}}),
    do: from(q in query, where: field(q, ^column) <= ^value)

  def where_condition(query, {column, {"eq", value}}),
    do: from(q in query, where: field(q, ^column) == ^value)

  def where_condition(query, {:order_by, {"desc", column}}),
    do: from(q in query, order_by: [desc: field(q, ^String.to_atom(column))])

  def where_condition(query, {:order_by, {"asc", column}}),
    do: from(q in query, order_by: [asc: field(q, ^String.to_atom(column))])

  @doc """
  where_condition(query, {column, {operator, operand}})

  This function generates a `within` geospatial query condition if the value contains
  some `coordinates` and an `srid`.
  """
  def where_condition(query, {column, {"in", %Geo.Polygon{} = polygon}}) do
    from(q in query, where: st_within(field(q, ^column), ^polygon))
  end

  @doc """
  where_condition(query, {column, {operator, operand}})

  This function generates a ranged query for the given bounds.
  """
  def where_condition(query, {column, {"in", %{"lower" => lower, "upper" => upper}}}) do
    case NaiveDateTime.from_iso8601(lower) do
      {:ok, lower} ->
        case NaiveDateTime.from_iso8601(upper) do
          {:ok, upper} ->
            where_condition(query, {column, {"ge", lower}})
            |> where_condition({column, {"le", upper}})

          _ ->
            query
        end

      _ ->
        query
    end
  end

  @doc """
  Generates an intersection query for a given geom. This condition is pretty much only
  used for the `bbox` filter when applied to metadata records.
  """
  def where_condition(query, {column, {"intersects", %Geo.Polygon{} = polygon}}) do
    from(q in query, where: st_intersects(field(q, ^column), ^polygon))
  end

  @doc """
  Shortcut for {column}=eq:{value}. User can provide the conditions as just {column}={value}.
  """
  def where_condition(query, {column, value}) do
    from(q in query, where: field(q, ^column) == ^value)
  end

  @doc """
  This function provides an accessible way of creating a query with multiple
  conditions. The keys correspond to columns, and the values correspond to
  operators and operands.

  ## Examples

      iex> params = %{
      ...>   "Inserted At" => {"le", "2000-01-01 13:30:15"},
      ...>   "updated_at" => {"lt", "2000-01-01 13:30:15"},
      ...>   "Float Column" => {"ge", 0.0},
      ...>   "integer_column" => {"gt", 42},
      ...>   "String Column" => {"eq", "hello!"}
      ...> }
      iex> Model |> map_to_query(params)

  """
  def map_to_query(query, []), do: query

  def map_to_query(query, params) when is_map(params),
    do: map_to_query(query, Map.to_list(params))

  def map_to_query(query, [condition_tuple | params]) do
    map_to_query(query |> where_condition(condition_tuple), params)
  end

  @doc """
  Truncates a database table, lives here for now until I can find a better place for it.

  todo(heyzoos) add an informative error if you receive something that isn't a struct
    - usually caused by passing an atom without aliasing it
    - or caused by not being an ecto schema

  """
  def truncate([]), do: :ok

  def truncate([schema | tail]) do
    truncate(schema)
    truncate(tail)
  end

  def truncate(schema) do
    {nil, table} = schema.__struct__.__meta__.source
    Ecto.Adapters.SQL.query!(Repo, "truncate \"#{table}\" cascade;", [])
  end
end
