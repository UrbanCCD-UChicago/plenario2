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

  def tuple_to_where_condition(query, {column, {operator, value}}) do
    case operator do
      "le" ->
        query |> where(^String.to_atom(column) <= ^value)
    end
  end

  def map_to_query(query, []) do
    query
  end

  def map_to_query(query, params) when is_map(params) do
    map_to_query(query, Map.to_list(params))
  end

  def map_to_query(query, [condition_tuple | params]) do
    map_to_query(query |> tuple_to_where_condition(condition_tuple), params)
  end
end
