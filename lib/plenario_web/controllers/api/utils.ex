defmodule PlenarioWeb.Api.Utils do
  import Ecto.Query

  @doc """
  Utility function for rendering a `Scrivener.Page` of results. Even if the
  controller actions that produce these pages are different, there's enough
  in common that they can share a rendering function.
  """
  def render_page(conn, view, params, entries, page) do
    Phoenix.Controller.render(conn, view, %{
      links: generate_links(conn, page),
      params: Map.new(params),
      data_count: length(entries),
      total_pages: page.total_pages,
      total_records: page.total_entries,
      data: entries})
  end

  def generate_links(conn, page) do
    page_number = page.page_number
    total_pages = page.total_pages
    page_size = page.page_size

    # Remove the pagination parameters so when we reconstruct the query string,
    # we don't repeat them unnecessarily.
    #
    # Also sometimes a "" can sneak in? This guards against that.
    all_params = String.split(conn.query_string, "&") |> Enum.filter(&(&1 != ""))
    non_page_params = Enum.filter(all_params, fn param ->
      [key, _] = String.split(param, "=")
      key not in ["page", "page_size"]
    end)

    # If we're on page one, then there is no previous link
    previous_page_number = if page_number == 1, do: nil, else: page_number - 1

    # If we're on the last page, then there is no next page
    next_page_number = if page_number == total_pages, do: nil, else: page_number + 1

    # And of course
    current_page_number = page_number

    # Construct the query strings
    previous_page_url = construct_url(conn, non_page_params, page_size, previous_page_number)
    next_page_url = construct_url(conn, non_page_params, page_size, next_page_number)
    current_page_url = construct_url(conn, non_page_params, page_size, current_page_number)

    %{
      previous: previous_page_url,
      current: current_page_url,
      next: next_page_url
    }
  end

  def construct_url(conn, params, page_size, nil), do: nil
  def construct_url(conn, params, page_size, page) do
    params_kwlist = Enum.map(params, fn param ->
      [key, value] = String.split(param, "=")
      {key, value}
    end) ++ [page_size: page_size, page: page]
    PlenarioWeb.Router.Helpers.detail_url(conn, :get, conn.params["slug"], params_kwlist)
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

  @doc """
  This function provides an accessible way of creating a query with multiple
  conditions. The keys correspond to columns, and the values correspond to
  operators and operands.

  ## Examples

      iex> params = %{
      ...>   "Inserted At" => {"le", ~N[2000-01-01 13:30:15]},
      ...>   "updated_at" => {"lt", ~N[2000-01-01 13:30:15]},
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

  @doc """
  Attempts to derive a datetime from a string. The string can specify a date or
  a datetime, and the function will produce a naive datetime. If it fails to
  parse a datetime, it will return a tuple specifying the error.

  ## Examples

      iex> to_naive_datetime("2000-01-01")
      {:ok, datetime}

      iex> to_naive_datetime("2000-01-01T00:00:00")
      {:ok, datetime}

      iex> to_naive_datetime("nani")
      {:error, message}

  """
  def to_naive_datetime(string) do
    case Date.from_iso8601(string) do
      {:ok, date} ->
        date_erl = Date.to_erl(date)
        {:ok, NaiveDateTime.from_erl!({date_erl}, {0, 0, 0})}
      {:error, _} ->
        case NaiveDateTime.from_iso8601(string) do
          {:ok, datetime} -> {:ok, datetime}
          {:error, message, _} -> {:error, message}
        end
    end
  end
end
