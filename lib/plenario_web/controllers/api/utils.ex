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
  def where_condition(query, {column, {"gt", value}}), do: where(query, ^String.to_atom(column) > ^value)
  def where_condition(query, {column, {"eq", value}}), do: where(query, ^String.to_atom(column) == ^value)

  def map_to_query(query, []), do: query
  def map_to_query(query, params) when is_map(params), do: map_to_query(query, Map.to_list(params))
  def map_to_query(query, [condition_tuple | params]) do
    map_to_query(query |> where_condition(condition_tuple), params)
  end
end
