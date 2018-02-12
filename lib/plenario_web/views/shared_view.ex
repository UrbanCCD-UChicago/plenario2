defmodule PlenarioWeb.SharedView do
  use PlenarioWeb, :shared_view

  def render_map(opts \\ []) do
    defaults = [
      map_id: "map",
      map_height: 500,
      map_center: "[41.9, -87.7]",
      map_zoom: 10,
      draw_controls: false,
      form_input_coords: "coords",
      bbox: nil,
      points: nil
    ]
    assigns = Keyword.merge(defaults, opts)
    render(PlenarioWeb.SharedView, "map.html", assigns)
  end
end
