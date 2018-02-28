defmodule PlenarioWeb.Web.PageController do
  use PlenarioWeb, :web_controller

  import Ecto.Query

  alias Plenario.Schemas.Meta

  alias Plenario.{Repo, ModelRegistry}

  def index(conn, _), do: render(conn, "index.html")

  def explorer(conn, params) do
    zoom = Map.get(params, "zoom", nil)
    coords = Map.get(params, "coords", nil)
    starts = Map.get(params, "starting_on", nil)
    ends = Map.get(params, "ending_on", nil)

    do_explorer(zoom, coords, starts, ends, conn)
  end

  defp do_explorer(nil, nil, nil, nil, conn) do
    render(conn, "explorer.html",
      map_center: "[41.9, -87.7]",
      map_zoom: 10,
      bbox: nil,
      starts: "",
      ends: ""
    )
  end
  defp do_explorer(zoom, coords, starts, ends, conn) do
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
      map_zoom: zoom,
      bbox: "#{inspect(map_bbox)}",
      starts: starts,
      ends: ends)
  end

  def aot_explorer(conn, params) do
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
    case Ecto.Adapters.SQL.query(Repo, sql) do
      {:ok, result} ->
        labels =
          for [{{y, mo, d}, {h, mi, s, _}} | _] <- result.rows do
            case NaiveDateTime.from_erl({{y, mo, d}, {h, mi, s}}) do
              {:ok, ndt} -> ndt
              _ -> ""
            end
          end

        temps = for row <- result.rows, do: Enum.at(row, 1)
        temps_data = [{"Average Temperature", temps}]
        humid = for row <- result.rows, do: Enum.at(row, 2)
        humid_data = [{"Average Humidity", humid}]


      {:error, _} ->
        labels = nil
        data = nil
    end

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
    case Ecto.Adapters.SQL.query(Repo, sql) do
      {:ok, result} ->
        temp_hm_data =
          for row <- result.rows do
            latlong = Enum.at(row, 0)
            [lat, long] = String.split(latlong, ",")
            avg = Enum.at(row, 1)
            {lat, long, avg}
          end

      {:error, _} ->
        temp_hm_data = []
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
    case Ecto.Adapters.SQL.query(Repo, sql) do
      {:ok, result} ->
        humid_hm_data =
          for row <- result.rows do
            latlong = Enum.at(row, 0)
            [lat, long] = String.split(latlong, ",")
            avg = Enum.at(row, 1)
            {lat, long, avg}
          end

      {:error, _} ->
        humid_hm_data = []
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
