defmodule PlenarioWeb.Api.Utils do
  def render_page(conn, view, params, entries, page) do
    Phoenix.Controller.render(conn, view, %{
      params: Map.new(params),
      data_count: length(entries),
      total_pages: page.total_pages,
      total_records: page.total_entries,
      data: entries})
  end
end
