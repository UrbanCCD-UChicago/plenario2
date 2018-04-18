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

  def where_condition(query, {column, {"le", value}}), do: where(query, ^String.to_atom(column) <= ^value)
  def where_condition(query, {column, {"lt", value}}), do: where(query, ^String.to_atom(column) < ^value)
  def where_condition(query, {column, {"ge", value}}), do: where(query, ^String.to_atom(column) >= ^value)
  def where_condition(query, {column, {"gt", value}}) do
    from(q in query, where: field(q, ^String.to_atom(column)) > ^value)
  end
  def where_condition(query, {column, {"eq", value}}), do: where(query, ^String.to_atom(column) == ^value)

  def map_to_query(query, []), do: query
  def map_to_query(query, params) when is_map(params), do: map_to_query(query, Map.to_list(params))
  def map_to_query(query, [condition_tuple | params]) do
    map_to_query(query |> where_condition(condition_tuple), params)
  end

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
