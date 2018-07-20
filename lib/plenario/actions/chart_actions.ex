defmodule Plenario.Actions.ChartActions do
  import Ecto.Query

  import Geo.PostGIS, only: [st_contains: 2]

  alias Plenario.{
    ModelRegistry,
    Repo
  }

  alias Plenario.Schemas.{
    Chart,
    ChartDataset
  }

  ##
  # regular, boring crud stuff for controller

  def get(id) do
    Chart
    |> where([c], c.id == ^id)
    |> preload(datasets: :chart, meta: :charts)
    |> Repo.one!()
  end

  def new, do: Chart.changeset()

  def create(params), do: Chart.changeset(%Chart{}, params) |> Repo.insert()

  def edit(id), do: get(id) |> Chart.changeset()

  def update(id, params), do: get(id) |> Chart.changeset(params) |> Repo.update()

  ##
  # fun aggregate stuff

  def get_agg_data(id, params) do
    chart = get(id)
    model = ModelRegistry.lookup(chart.meta.slug)

    granularity = parse_granularity(params)
    bbox = parse_bbox(params)
    time_range = parse_time_range(params)

    query =
      build_query(granularity, chart, model)
      |> apply_group_by_field(chart)
      |> apply_datasets(chart)
      |> apply_bbox(chart, bbox)
      |> apply_time_range(chart, time_range)

    # ecto cannot fold the values back in neatly. i think it's a casting
    # issue. this works just a well -- we really only the values and not
    # full blown structs anyway.
    {sql, params} = Ecto.Adapters.SQL.to_sql(:all, Repo, query)
    %Postgrex.Result{rows: rows} = Repo.query!(sql, params)

    aggregate_results(rows, chart)
  end

  defp build_query(:day, %Chart{timestamp_field: tsf}, model) do
    tsf = String.to_atom(tsf)

    model
    |> select([m], type(
      fragment("date_trunc('day', ?)", field(m, ^tsf)),
      :naive_datetime
    ))
    |> group_by([m], fragment("date_trunc('day', ?)", field(m, ^tsf)))
  end

  defp build_query(:week, %Chart{timestamp_field: tsf}, model) do
    tsf = String.to_atom(tsf)

    model
    |> select([m], type(
      fragment("date_trunc('week', ?)", field(m, ^tsf)),
      :naive_datetime
    ))
    |> group_by([m], fragment("date_trunc('week', ?)", field(m, ^tsf)))
  end

  defp build_query(:month, %Chart{timestamp_field: tsf}, model) do
    tsf = String.to_atom(tsf)

    model
    |> select([m], type(
      fragment("date_trunc('month', ?)", field(m, ^tsf)),
      :naive_datetime
    ))
    |> group_by([m], fragment("date_trunc('month', ?)", field(m, ^tsf)))
  end

  defp build_query(:year, %Chart{timestamp_field: tsf}, model) do
    tsf = String.to_atom(tsf)

    model
    |> select([m], type(
      fragment("date_trunc('year', ?)", field(m, ^tsf)),
      :naive_datetime
    ))
    |> group_by([m], fragment("date_trunc('year', ?)", field(m, ^tsf)))
  end

  defp apply_group_by_field(query, %Chart{group_by_field: nil}), do: query
  defp apply_group_by_field(query, %Chart{group_by_field: gbf}) do
    gbf = String.to_atom(gbf)

    query
    |> select_merge([m], field(m, ^gbf))
    |> group_by([m], field(m, ^gbf))
  end

  defp apply_datasets(query, %Chart{datasets: datasets}) do
    datasets
    |> Enum.reduce(query, fn ds, q -> apply_dataset(ds, q) end)
  end

  defp apply_dataset(%ChartDataset{func: "count", field_name: "*"}, query) do
    query
    |> select_merge([m], fragment("count(*)"))
  end

  defp apply_dataset(%ChartDataset{func: "count", field_name: fname}, query) do
    fname = String.to_atom(fname)

    query
    |> select_merge([m], count(field(m, ^fname)))
  end

  defp apply_dataset(%ChartDataset{func: "avg", field_name: fname}, query) do
    fname = String.to_atom(fname)

    query
    |> select_merge([m], avg(field(m, ^fname)))
  end

  defp apply_dataset(%ChartDataset{func: "min", field_name: fname}, query) do
    fname = String.to_atom(fname)

    query
    |> select_merge([m], min(field(m, ^fname)))
  end

  defp apply_dataset(%ChartDataset{func: "max", field_name: fname}, query) do
    fname = String.to_atom(fname)

    query
    |> select_merge([m], max(field(m, ^fname)))
  end

  defp apply_bbox(query, _, nil), do: query
  defp apply_bbox(query, %Chart{point_field: pt}, bbox) do
    pt = String.to_atom(pt)

    query
    |> where([m], st_contains(^bbox, field(m, ^pt)))
  end

  defp apply_time_range(query, _, nil), do: query
  defp apply_time_range(query, %Chart{timestamp_field: ts}, time_range) do
    ts = String.to_atom(ts)

    query
    |> where([m], fragment("?::tsrange @> ?::timestamp", ^time_range, field(m, ^ts)))
  end

  defp aggregate_results(rows, %Chart{group_by_field: nil, datasets: ds}) do
    timestamps =
      rows
      |> Enum.map(& Enum.at(&1, 0))
      |> Enum.uniq()

    labels =
      ds
      |> Enum.map(& &1.label)

    datasets =
      labels
      |> Enum.with_index(1)
      |> Enum.map(fn {label, idx} ->
        values =
          rows
          |> Enum.map(& Enum.at(&1, idx))
        {label, values}
      end)
      |> Enum.into(%{})
      |> Enum.map(fn {k, v} -> %{label: k, data: v} end)

    timestamps =
      timestamps
      |> Enum.map(fn {ymd, {h, m, s, u}} -> NaiveDateTime.from_erl!({ymd, {h, m, s}}, {u, 6}) end)
      |> Enum.map(& String.to_atom("#{&1}"))

    %{labels: timestamps, datasets: datasets}
  end

  defp aggregate_results(rows, %Chart{group_by_field: gbf}) when not is_nil(gbf) do
    timestamps =
      rows
      |> Enum.map(& Enum.at(&1, 0))
      |> Enum.uniq()

    ds_labels =
      rows
      |> Enum.map(& Enum.at(&1, 1))
      |> Enum.uniq()

    res_map =
      rows
      |> Enum.reduce(%{}, fn row, acc ->
        ts = Enum.at(row, 0)
        gbf = Enum.at(row, 1)
        take = (length(row) - 2) * -1
        values = Enum.take(row, take)
        entry = Map.get(acc, {ts, gbf}, [])
        entry = entry ++ values
        Map.merge(acc, %{{ts, gbf} => entry})
      end)

    datasets =
      ds_labels
      |> Enum.reduce(%{}, fn label, acc ->
        values =
          timestamps
          |> Enum.map(& Map.get(res_map, {&1, label}, nil))
          |> List.flatten()
        Map.merge(acc, %{label => values})
      end)
      |> Enum.map(fn {k, v} -> %{label: k, data: v} end)

    timestamps =
      timestamps
      |> Enum.map(fn {ymd, {h, m, s, u}} -> NaiveDateTime.from_erl!({ymd, {h, m, s}}, {u, 6}) end)
      |> Enum.map(& String.to_atom("#{&1}"))

    %{labels: timestamps, datasets: datasets}
  end

  # controller parsing helpers

  @granularities ["day", "week", "month", "year"]
  @default_granularity :week

  defp parse_granularity(params) do
    granularity = Map.get(params, "granularity")
    cond do
      is_nil(granularity) ->
        @default_granularity

      !Enum.member?(@granularities, granularity) ->
        @default_granularity

      true ->
        String.to_atom(granularity)
    end
  end

  defp parse_bbox(params) do
    bbox = Map.get(params, "bbox")
    cond do
      is_binary(bbox) ->
        case Poison.decode(bbox) do
          {:ok, json} ->
            cond do
              is_list(json) ->
                coords =
                  Enum.map(json, fn p ->
                    Enum.map(p, fn [lat, lon] -> {lon, lat} end)
                  end)
                %Geo.Polygon{coordinates: coords, srid: 4326}

              is_map(json) ->
                %{
                  "_northEast" => %{"lat" => max_lat, "lng" => min_lon},
                  "_southWest" => %{"lat" => min_lat, "lng" => max_lon}
                } = json
                %Geo.Polygon{coordinates: [[
                  {max_lon, max_lat},
                  {min_lon, max_lat},
                  {min_lon, min_lat},
                  {max_lon, min_lat},
                  {max_lon, max_lat}
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

  defp parse_time_range(params) do
    starts = Map.get(params, "starts")
    ends = Map.get(params, "ends")

    case is_nil(starts) and is_nil(ends) do
      true ->
        nil

      false ->
        starts =
          case NaiveDateTime.from_iso8601(starts) do
            {:error, _} ->
              Timex.shift(NaiveDateTime.utc_now(), years: -1)

            {_, ndt} ->
              ndt
          end
        ends =
          case NaiveDateTime.from_iso8601(ends) do
            {:error, _} ->
              NaiveDateTime.utc_now()

            {_, ndt} ->
              ndt
          end

        Plenario.TsRange.new(starts, ends) |> Plenario.TsRange.to_postgrex()
      end
  end
end
