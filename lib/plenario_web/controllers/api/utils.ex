defmodule PlenarioWeb.Api.Utils do
  import Ecto.Query
  import PlenarioWeb.Router.Helpers, only: [detail_url: 4, list_url: 3, aot_url: 3]
  import Geo.PostGIS

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
      data: entries})
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
    non_page_params = Enum.filter(conn.params, fn {key, _} ->
      key not in ["page", "page_size"]
    end)

    # If we're on page one, then there is no previous link
    previous_page_number = if page_number == 1, do: nil, else: page_number - 1

    # If we're on the last page, then there is no next page
    next_page_number = if page_number == total_pages, do: nil, else: page_number + 1

    # And of course
    current_page_number = page_number

    # Check if there is a `inserted_at` filter present, if not - add one
    datetime_now = NaiveDateTime.to_iso8601(NaiveDateTime.utc_now)

    kwlist_params = Enum.map(non_page_params, fn {k, v} ->
      if is_atom(k) do
        {k, v}
      else
        {String.to_atom(k), v}
      end
    end)

    inserted_at_params = case Keyword.has_key?(kwlist_params, :inserted_at) do
      true -> []
      false -> [inserted_at: "le:#{datetime_now}"]
    end

    params = kwlist_params ++ inserted_at_params

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
  def where_condition(query, {column, {"gt", value}}), do: from(q in query, where: field(q, ^column) > ^value)
  def where_condition(query, {column, {"ge", value}}), do: from(q in query, where: field(q, ^column) >= ^value)
  def where_condition(query, {column, {"lt", value}}), do: from(q in query, where: field(q, ^column) < ^value)
  def where_condition(query, {column, {"le", value}}), do: from(q in query, where: field(q, ^column) <= ^value)
  def where_condition(query, {column, {"eq", value}}), do: from(q in query, where: field(q, ^column) == ^value)
  def where_condition(query, {:order_by, {"desc", column}}), do: from(q in query, order_by: [desc: field(q, ^String.to_atom(column))])
  def where_condition(query, {:order_by, {"asc", column}}), do: from(q in query, order_by: [asc: field(q, ^String.to_atom(column))])

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
    where_condition(query, {column, {"ge", lower}})
    |> where_condition({column, {"le", upper}})
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
  def map_to_query(query, params) when is_map(params), do: map_to_query(query, Map.to_list(params))
  def map_to_query(query, [condition_tuple | params]) do
    map_to_query(query |> where_condition(condition_tuple), params)
  end
end
