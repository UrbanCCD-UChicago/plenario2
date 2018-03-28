defmodule PlenarioWeb.Web.PageController do
  use PlenarioWeb, :web_controller

  alias Plenario.Schemas.Meta
  alias Plenario.{Repo, ModelRegistry}

  import Ecto.Query
  import Plug.Conn

  def index(conn, _), do: render(conn, "index.html")

  def explorer(conn, params) do
    zoom = Map.get(params, "zoom", nil)
    coords = Map.get(params, "coords", nil)
    starts = Map.get(params, "starting_on", nil)
    ends = Map.get(params, "ending_on", nil)

    {startdt, conn} = parse_dt(conn, starts)
    {enddt, conn} = parse_dt(conn, ends)

    do_explorer(zoom, coords, startdt, enddt, conn)
  end

  defp parse_dt(conn, nil) do
    {nil, conn}
  end

  defp parse_dt(conn, datetime_string) do
    case DateTime.from_iso8601("#{datetime_string}T00:00:00.0Z") do
      {_, datetime, _} ->
        {datetime, conn}
      {:error, :invalid_format} ->
        {nil, put_flash(conn, :error, 
          "Invalid datetime #{datetime_string}, must be formatted as YYYY-MM-DD")}
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
    meta = Repo.one(from m in Meta, where: m.name == "Array of Things Chicago")
    model = ModelRegistry.lookup(meta.slug)

    point_data =
      model
      |> select([:latitude, :longitude, :human_address, :node_id])
      |> distinct([:latitude, :longitude])
      |> limit(30)
      |> Repo.all()

    points =
      for p <- point_data do
        {"[#{p.latitude}, #{p.longitude}]", p.human_address, p.node_id}
      end

    temps_query = """
    SELECT
      date_trunc('hour', "timestamp"),
      avg(("observations"->'BMP180'->>'temperature')::numeric),
      avg(("observations"->'HTU21D'->>'humidity')::numeric)
    FROM
      "<%= table_name %>"
    GROUP BY
      date_trunc('hour', "timestamp")
    ORDER BY
      date_trunc('hour', "timestamp") DESC
    LIMIT 24
    ;
    """
    sql = EEx.eval_string(temps_query, [table_name: meta.table_name], trim: true)

    {labels, rows} =
      case Ecto.Adapters.SQL.query(Repo, sql) do
        {:ok, result} ->
          {for [{{y, mo, d}, {h, mi, s, _}} | _] <- result.rows do
            case NaiveDateTime.from_erl({{y, mo, d}, {h, mi, s}}) do
              {:ok, ndt} -> ndt
              _ -> ""
            end
          end, result.rows}

        {:error, _} ->
          {[], []}
      end

    reversed_rows = Enum.reverse(rows)
    temps = for row <- reversed_rows, do: Enum.at(row, 1)
    temps_data = [{"Average Temperature", temps}]
    humid = for row <- reversed_rows, do: Enum.at(row, 2)
    humid_data = [{"Average Humidity", humid}]

    temp_hm_query = """
    SELECT
      subq."latitude" || ',' || subq."longitude" AS latlong,
      AVG((subq."observations"->'BMP180'->>'temperature')::numeric)
    FROM (
      SELECT *
      FROM "<%= table_name %>"
      WHERE "timestamp" >= current_date - interval '24' hour
    ) AS subq
    GROUP BY
      latlong
    ;
    """
    sql = EEx.eval_string(temp_hm_query, [table_name: meta.table_name], trim: true)

    temp_hm_data = 
      case Ecto.Adapters.SQL.query(Repo, sql) do
        {:ok, result} ->
          for row <- result.rows do
            latlong = Enum.at(row, 0)
            [lat, long] = String.split(latlong, ",")
            avg = Enum.at(row, 1)
            {lat, long, avg}
          end

        {:error, _} ->
          []
      end

    humid_hm_query = """
    SELECT
      subq."latitude" || ',' || subq."longitude" AS latlong,
      AVG((subq."observations"->'HTU21D'->>'humidity')::numeric)
    FROM (
      SELECT *
      FROM "<%= table_name %>"
      WHERE "timestamp" >= current_date - interval '24' hour
    ) AS subq
    GROUP BY
      latlong
    ;
    """
    sql = EEx.eval_string(humid_hm_query, [table_name: meta.table_name], trim: true)

    humid_hm_data = 
      case Ecto.Adapters.SQL.query(Repo, sql) do
        {:ok, result} ->
          for row <- result.rows do
            latlong = Enum.at(row, 0)
            [lat, long] = String.split(latlong, ",")
            avg = Enum.at(row, 1)
            {lat, long, avg}
          end

        {:error, _} ->
          []
      end

    render(conn, "aot-explorer.html",
      points: points,
      labels: labels,
      temps_data: temps_data,
      humid_data: humid_data,
      temp_hm_data: temp_hm_data,
      humid_hm_data: humid_hm_data
    )
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
