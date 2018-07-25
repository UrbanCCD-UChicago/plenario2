defmodule PlenarioWeb.Web.PageController do
  use PlenarioWeb, :web_controller

  import Ecto.Query
  import Plug.Conn

  alias Plenario.Repo
  alias PlenarioAot.{AotData, AotMeta}

  def assign_s3_path(conn, opts) do
    assign(
      conn,
      :s3_asset_path,
      Map.get(
        %{
          "dev.plenar.io":  "https://s3.us-east-2.amazonaws.com/plenario2-assets-staging",
          "plenar.io": "https://s3.us-east-2.amazonaws.com/plenario2-assets"
        },
        conn.host,
        "https://s3.us-east-2.amazonaws.com/plenario2-assets-dev"
      )
    )
  end

  plug :assign_s3_path

  ##
  # flat pages

  def index(conn, _), do: render(conn, "index.html")

  def docs(conn, _), do: render(conn, "docs.html")

  ##
  # regular explorer

  @default_zoom 10
  @default_center "[41.9, -87.7]"
  @default_granularity "week"

  # first load

  def explorer(conn, params) when params == %{} do
    render conn, "explorer.html",
      results: nil,
      granularity: @default_granularity,
      map_center: @default_center,
      map_zoom: @default_zoom,
      bbox: nil,
      starts: nil,
      ends: nil
  end

  # user submits form

  def explorer(conn, params) do
    granularity = parse_granularity(params)
    zoom = parse_zoom(params)

    starts = parse_date(params, "starting_on")
    ends = parse_date(params, "ending_on")
    time_range = make_time_range(starts, ends)

    conn =
      case is_nil(time_range) do
        true ->
          conn
          |> put_status(:bad_request)
          |> put_flash(:error, "You must select a time range with a starting date earlier than the ending date.")

        false ->
          conn
      end

    bbox = parse_coords(params)
    center = find_center(bbox)

    conn =
      case is_nil(bbox) do
        true ->
          existing_message =
            case get_flash(conn)[:error] do
              nil -> ""
              value -> value
            end

          message =
            existing_message <>
            "You must select an area on the map to search data sets."

          conn
          |> put_status(:bad_request)
          |> put_flash(:error, message)

        false ->
          conn
      end

    results =
      case is_nil(bbox) do
        true ->
          nil

        false ->
          Plenario.search_data_sets(bbox, time_range)
      end

    coords =
      case is_nil(bbox) do
        true ->
          nil

        false ->
          bbox.coordinates |> Poison.encode!()
      end

    render conn, "explorer.html",
      results: results,
      granularity: granularity,
      map_center: center,
      map_zoom: zoom,
      bbox: coords,
      starts: starts,
      ends: ends
  end

  defp parse_granularity(params), do: Map.get(params, "granularity", @default_granularity)

  defp parse_zoom(params), do: Map.get(params, "zoom", @default_zoom)

  defp parse_date(params, key) do
    case Map.get(params, key) do
      nil ->
        nil

      string ->
        case NaiveDateTime.from_iso8601("#{string}T00:00:00.0") do
          {:error, _} ->
            nil

          {_, value} ->
            value
        end
    end
  end

  defp make_time_range(%NaiveDateTime{} = starts, %NaiveDateTime{} = ends) do
    case NaiveDateTime.compare(starts, ends) do
      :gt ->
        nil

      _ ->
        Plenario.TsRange.new(starts, ends)
    end
  end
  defp make_time_range(_, _), do: nil

  defp parse_coords(params) do
    bbox = Map.get(params, "coords")
    cond do
      is_binary(bbox) ->
        case Poison.decode(bbox) do
          {:ok, json} ->
            cond do
              is_list(json) ->
                coords = for [lat, lon] <- json, do: {lat, lon}
                first = List.first(coords)
                coords = coords ++ [first]
                %Geo.Polygon{coordinates: [coords], srid: 4326}

              is_map(json) ->
                %{
                  "_northEast" => %{"lat" => max_lat, "lng" => min_lon},
                  "_southWest" => %{"lat" => min_lat, "lng" => max_lon}
                } = json
                %Geo.Polygon{coordinates: [[
                  {max_lat, max_lon},
                  {min_lat, max_lon},
                  {min_lat, min_lon},
                  {max_lat, min_lon},
                  {max_lat, max_lon}
                ]], srid: 4326}

              true ->
                nil
            end

          _ ->
            nil
        end

      true ->
        nil
    end
  end

  defp find_center(nil), do: @default_center
  defp find_center(bbox) do
    coords = List.first(bbox.coordinates)

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

  ##
  # aot explorer

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

  @red "255,99,132"
  @blue "54,162,235"
  @yellow "255,206,86"
  @green "75,192,192"
  @purple "153,102,255"

  defp bgrnd_color(base), do: "rgba(#{base},0.2)"

  defp border_color(base), do: "rgba(#{base},1)"

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
end
