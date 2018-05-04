defmodule PlenarioWeb.Web.PageController do
  use PlenarioWeb, :web_controller

  import Ecto.Query

  import Plug.Conn

  alias Plenario.Repo

  alias PlenarioAot.{AotData, AotMeta}

  def index(conn, _), do: render(conn, "index.html")

  def explorer(conn, params) do
    zoom = Map.get(params, "zoom", nil)
    coords = Map.get(params, "coords", nil)
    starts = Map.get(params, "starting_on", nil)
    ends = Map.get(params, "ending_on", nil)

    {startdt, conn} = parse_date(conn, starts)
    {enddt, conn} = parse_date(conn, ends)

    do_explorer(zoom, coords, startdt, enddt, conn)
  end

  defp parse_date(conn, nil) do
    {nil, conn}
  end

  defp parse_date(conn, date_string) do
    case DateTime.from_iso8601("#{date_string}T00:00:00.0Z") do
      {_, datetime, _} ->
        {datetime, conn}
      {:error, :invalid_format} ->
        {nil, put_flash(conn, :error,
          "Invalid date #{date_string}, must be formatted as YYYY-MM-DD")}
    end
  end

  defp do_explorer(nil, nil, nil, nil, conn) do
    render_explorer(conn, nil, "[41.9, -87.7]", 10, nil, "", "")
  end

  defp do_explorer(_, _, _, _, conn = %Plug.Conn{private: %{:phoenix_flash => %{"error" => _}}}) do
    render_explorer(conn, nil, "[41.9, -87.7]", 10, nil, "", "")
  end

  defp do_explorer(zoom, coords, startdt, enddt, conn) when startdt >= enddt do
    do_explorer(zoom, coords, startdt, enddt, put_flash(conn, :error,
      "The starting datetime #{startdt} cannot be greater than the ending datetime #{enddt}"))
  end

  defp do_explorer(zoom, coords, startdt, enddt, conn) do
    coords = Poison.decode!(coords)
    bbox = build_polygon(coords)

    map_bbox =
      List.first(bbox.coordinates)
      |> Enum.map(fn {lat, lon} -> [lat, lon] end)

    {:ok, range} = Plenario.TsTzRange.dump([startdt, enddt])

    center = get_poly_center(bbox)
    results = Plenario.search_data_sets(bbox, range)
    render_explorer(conn, results, center, zoom, inspect(map_bbox), startdt, enddt)
  end

  defp render_explorer(conn, results, center, zoom, bbox, startdt, enddt) do
    render(conn, "explorer.html",
      results: results,
      map_center: center,
      map_zoom: zoom,
      bbox: bbox,
      starts: startdt,
      ends: enddt)
  end

  def aot_explorer(conn, _params) do
    meta =
      try do
        Repo.get_by!(AotMeta, slug: "chicago")
      rescue
        _ -> Repo.one!(AotMeta)
      end

    node_locations_data =
      AotData
      |> select([:latitude, :longitude, :human_address, :node_id])
      |> distinct([:latitude, :longitude])
      |> where([d], fragment("? >= current_date - interval '24' hour", d.timestamp))
      |> where([d], d.aot_meta_id == ^meta.id)
      |> Repo.all()
      |> Enum.map(fn row ->
        {
          "[#{row.latitude}, #{row.longitude}]",
          String.trim(row.human_address),
          row.node_id
        }
      end)

    temp_humid_graph_data =
      AotData
      |> select([d], %{
        trunc_timestamp: fragment("date_trunc('hour', ?) as trunc_timestamp", d.timestamp),
        avg_temp: fragment("avg((observations->'HTU21D'->>'temperature')::float)"),
        avg_humid: fragment("avg((observations->'HTU21D'->>'humidity')::float)")
      })
      |> where([d], fragment("? >= current_date - interval '24' hour", d.timestamp))
      |> where([d], d.aot_meta_id == ^meta.id)
      |> group_by(fragment("trunc_timestamp"))
      |> order_by(asc: fragment("trunc_timestamp"))
      |> Repo.all()
      |> Enum.map(fn row ->
        [
          Timex.format!(row.trunc_timestamp, "{ISOdate} {ISOtime}"),
          row.avg_temp,
          row.avg_humid
        ]
      end)
      |> format_line_chart(["Average Temperature", "Average Humidity"])

    temp_heatmap_data =
      AotData
      |> select([d], {
        d.latitude,
        d.longitude,
        fragment("(avg((observations->'HTU21D'->>'temperature')::float) * 2.1) + 20")
      })
      |> distinct([d], [d.latitude, d.longitude])
      |> where([d], fragment("? >= current_date - interval '24' hour", d.timestamp))
      |> where([d], d.aot_meta_id == ^meta.id)
      |> group_by([d], [d.latitude, d.longitude])
      |> Repo.all()
      |> Enum.reject(fn {_, _, temp} -> is_nil(temp) end)

    humid_heatmap_data =
      AotData
      |> select([d], {
        d.latitude,
        d.longitude,
        fragment("avg((observations->'HTU21D'->>'humidity')::float)")
      })
      |> distinct([d], [d.latitude, d.longitude])
      |> where([d], fragment("? >= current_date - interval '24' hour", d.timestamp))
      |> where([d], d.aot_meta_id == ^meta.id)
      |> group_by([d], [d.latitude, d.longitude])
      |> Repo.all()
      |> Enum.reject(fn {_, _, humid} -> is_nil(humid) end)

    render(conn, "aot-explorer.html", [
      points: node_locations_data,
      temp_hm_data: temp_heatmap_data,
      humid_hm_data: humid_heatmap_data,
      labels: temp_humid_graph_data[:labels],
      temps_data: Enum.at(temp_humid_graph_data[:datasets], 0),
      humid_data: Enum.at(temp_humid_graph_data[:datasets], 1)
    ])
  end

  @red "255, 99, 132"
  @blue "54, 162, 235"
  @yellow "255, 206, 86"
  @green "75, 192, 192"
  @purple "153, 102, 255"

  defp bgrnd_color(base), do: "rgba(#{base}, 0.2)"

  defp border_color(base), do: "rgba(#{base}, 1)"

  defp format_line_chart(records, keys) do
    labels = Enum.map(records, fn [dt | _] -> dt end)
    datasets =
      keys
      |> Enum.with_index(1)
      |> Enum.map(fn {key, index} ->
        data = Enum.map(records, fn row -> Enum.at(row, index) end)
        %{
          label: key,
          data: data,
          backgroundColor: Enum.at(Stream.cycle([@red, @blue, @yellow, @green, @purple]), index) |> bgrnd_color(),
          borderColor: Enum.at(Stream.cycle([@red, @blue, @yellow, @green, @purple]), index) |> border_color(),
          border: 1,
          fill: true
        }
      end)

    %{labels: labels, datasets: datasets}
  end

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
