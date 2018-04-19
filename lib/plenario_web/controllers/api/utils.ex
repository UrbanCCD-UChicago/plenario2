defmodule PlenarioWeb.Api.Utils do
  import Ecto.Query

  def render_page(conn, view, params, entries, page) do
    Phoenix.Controller.render(conn, view, %{
      params: Map.new(params),
      data_count: length(entries),
      total_pages: page.total_pages,
      total_records: page.total_entries,
      data: entries})
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
  These functions match against the `operand` and generate the appropriate
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
