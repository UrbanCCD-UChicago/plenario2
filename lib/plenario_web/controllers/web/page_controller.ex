defmodule PlenarioWeb.Web.PageController do
  use PlenarioWeb, :web_controller

  def index(conn, _), do: render(conn, "index.html")

  def explorer(conn, _) do
    render(conn, "explorer.html", map_center: "[41.9, -87.7]", bbox: nil, starts: "", ends: "")
  end

  def search_all_data_sets(conn, %{"coords" => coords, "starting_on" => starts, "ending_on" => ends} = params) do
    coords = Poison.decode!(coords)
    bbox = build_polygon(coords)

    map_center = get_poly_center(bbox)
    map_bbox =
      List.first(bbox.coordinates)
      |> Enum.map(fn {lat, lon} -> [lat, lon] end)

    {_, lower, _} = DateTime.from_iso8601("#{starts}T00:00:00.0Z")
    {_, upper, _} = DateTime.from_iso8601("#{ends}T00:00:00.0Z")
    {:ok, range} = Plenario.TsTzRange.dump([lower, upper])

    results = Plenario.search_data_sets(bbox, range)

    render(conn, "explorer.html",
      results: results,
      map_center: get_poly_center(bbox),
      bbox: "#{inspect(map_bbox)}",
      starts: starts,
      ends: ends)
  end

  def aot_explorer(conn, _), do: render(conn, "aot-explorer.html")

  defp build_polygon(coords) when is_list(coords) do
    coords = for [lat, lon] <- coords, do: {lat, lon}
    first = List.first(coords)
    coords = coords ++ [first]
    %Geo.Polygon{coordinates: [coords], srid: 4326}
  end

  defp build_polygon(coords) when is_map(coords) do
    %{
      "_northEast" => %{"lat" => max_lat, "lng" => min_lon},
      "_southWest" => %{"lat" => min_lat, "lng" => max_lon}
    } = coords
    %Geo.Polygon{coordinates: [[
      {max_lat, max_lon},
      {min_lat, max_lon},
      {min_lat, min_lon},
      {max_lat, min_lon},
      {max_lat, max_lon}
    ]], srid: 4326}
  end

  defp get_poly_center(%Geo.Polygon{} = poly) do
    coords = List.first(poly.coordinates)
    lats = for {l, _} <- coords, do: l
    lons = for {_, l} <- coords, do: l
    max_lat = Enum.max(lats)
    min_lat = Enum.min(lats)
    max_lon = Enum.max(lons)
    min_lon = Enum.min(lons)
    lat = (max_lat + min_lat) / 2
    lon = (max_lon + min_lon) / 2
    "[#{lat}, #{lon}]"
  end
  defp get_poly_center(_), do: "[41.9, -87.7]"
end
