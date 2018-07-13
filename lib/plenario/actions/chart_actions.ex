defmodule Plenario.Actions.ChartActions do
  import Ecto.Query

  import Geo.PostGIS, only: [st_contains: 2]

  alias Plenario.{
    ModelRegistry,
    Repo
  }

  alias Plenario.Schemas.{
    Chart,
    ChartDataset,
    DataSetField
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

    gb_func = get_group_by_func(chart)

    groups =
      select_groups(gb_func, granularity, model, chart.group_by_field)
      |> apply_bbox(chart.point_field, bbox)
      |> apply_time_range(chart.timestamp_field, time_range)
      |> Repo.all()
      |> Enum.map(& String.to_atom("#{&1}"))

    datasets =
      chart.datasets
      |> Enum.map(fn d ->
        data =
          select_dataset(gb_func, granularity, model, chart.group_by_field, d)
          |> apply_bbox(chart.point_field, bbox)
          |> apply_time_range(chart.timestamp_field, time_range)
          |> Repo.all()
          |> Enum.map(fn {k, v} -> {String.to_atom("#{k}"), v} end)

        selected_data =
          groups
          |> Enum.map(& Keyword.get(data, &1, 0))

        %{label: d.label, data: selected_data}
      end)

    %{labels: groups, datasets: datasets}
  end

  # agg helpers

  defp get_group_by_func(%Chart{meta_id: meta_id, group_by_field: fname}) do
    cond do
      # virtual dates are timestamps and should be truncated
      String.starts_with?(fname, "vdf") ->
        :date_trunc

      # virtual points use distinct
      String.starts_with?(fname, "vpf") ->
        :distinct

      # oh shit, it's a regular field and we need to look up its type
      true ->
        field =
          DataSetField
          |> where([d], d.meta_id == ^meta_id)
          |> where([d], d.name == ^fname)
          |> Repo.one!()

        if field.type == "timestamp", do: :date_trunc, else: :distinct
    end
  end

  defp apply_bbox(queryable, point_field, bbox) do
    case is_nil(bbox) do
      true ->
        queryable

      false ->
        queryable
        |> where([m], st_contains(^bbox, field(m, ^String.to_atom(point_field))))
    end
  end

  defp apply_time_range(queryable, timestamp_field, time_range) do
    case is_nil(time_range) do
      true ->
        queryable

      false ->
        queryable
        |> where([m], fragment("?::tsrange @> ?::timestamp", ^time_range, field(m, ^String.to_atom(timestamp_field))))
    end
  end

  # get groups (chart labels) by distinct values
  # params:
  #   - :distinct
  #   - granularity is unused
  #   - queryable is an ecto queryable
  #   - fname is the chart's group by field name

  defp select_groups(:distinct, _, queryable, fname) do
    queryable
    |> select([m], field(m, ^String.to_atom(fname)))
    |> distinct(true)
    |> where([m], not is_nil(field(m, ^String.to_atom(fname))))
    |> order_by([m], field(m, ^String.to_atom(fname)))
  end

  # get groups (chart labels) by date trunc
  # params:
  #   - :date_trunc
  #   - :day|week|whatever is the granularity of the date trunc
  #   - queryable is an ecto queryable
  #   - fname is the chart's group by field name

  defp select_groups(:date_trunc, :day, queryable, fname) do
    queryable
    |> select([m],
      type(
        fragment("date_trunc('day', ?)", field(m, ^String.to_atom(fname))),
        :naive_datetime
      )
    )
    |> distinct(true)
    |> where([m],
      not is_nil(fragment("date_trunc('day', ?)", field(m, ^String.to_atom(fname))))
    )
    |> order_by([m],
      fragment("date_trunc('day', ?)", field(m, ^String.to_atom(fname)))
    )
  end

  defp select_groups(:date_trunc, :week, queryable, fname) do
    queryable
    |> select([m],
      type(
        fragment("date_trunc('week', ?)", field(m, ^String.to_atom(fname))),
        :naive_datetime
      )
    )
    |> distinct(true)
    |> where([m],
      not is_nil(fragment("date_trunc('week', ?)", field(m, ^String.to_atom(fname))))
    )
    |> order_by([m],
      fragment("date_trunc('week', ?)", field(m, ^String.to_atom(fname)))
    )
  end

  defp select_groups(:date_trunc, :month, queryable, fname) do
    queryable
    |> select([m],
      type(
        fragment("date_trunc('month', ?)", field(m, ^String.to_atom(fname))),
        :naive_datetime
      )
    )
    |> distinct(true)
    |> where([m],
      not is_nil(fragment("date_trunc('month', ?)", field(m, ^String.to_atom(fname))))
    )
    |> order_by([m],
      fragment("date_trunc('month', ?)", field(m, ^String.to_atom(fname)))
    )
  end

  defp select_groups(:date_trunc, :year, queryable, fname) do
    queryable
    |> select([m],
      type(
        fragment("date_trunc('year', ?)", field(m, ^String.to_atom(fname))),
        :naive_datetime
      )
    )
    |> distinct(true)
    |> where([m],
      not is_nil(fragment("date_trunc('year', ?)", field(m, ^String.to_atom(fname))))
    )
    |> order_by([m],
      fragment("date_trunc('year', ?)", field(m, ^String.to_atom(fname)))
    )
  end

  # get dataset (dataset label and data) by distinct
  # params:
  #   - :distinct
  #   - granularity is unused
  #   - chart's group by field name
  #   - chart dataset record

  defp select_dataset(:distinct, _, queryable, gbfname, %ChartDataset{func: "count", field_name: fname}) do
    queryable
    |> select([m],
      {
        field(m, ^String.to_atom(gbfname)),
        count(field(m, ^String.to_atom(fname)))
      }
    )
    |> where([m], not is_nil(field(m, ^String.to_atom(gbfname))))
    |> group_by([m], field(m, ^String.to_atom(gbfname)))
  end

  defp select_dataset(:distinct, _, queryable, gbfname, %ChartDataset{func: "avg", field_name: fname}) do
    queryable
    |> select([m],
      {
        field(m, ^String.to_atom(gbfname)),
        avg(field(m, ^String.to_atom(fname)))
      }
    )
    |> where([m], not is_nil(field(m, ^String.to_atom(gbfname))))
    |> group_by([m], field(m, ^String.to_atom(gbfname)))
  end

  defp select_dataset(:distinct, _, queryable, gbfname, %ChartDataset{func: "min", field_name: fname}) do
    queryable
    |> select([m],
      {
        field(m, ^String.to_atom(gbfname)),
        min(field(m, ^String.to_atom(fname)))
      }
    )
    |> where([m], not is_nil(field(m, ^String.to_atom(gbfname))))
    |> group_by([m], field(m, ^String.to_atom(gbfname)))
  end

  defp select_dataset(:distinct, _, queryable, gbfname, %ChartDataset{func: "max", field_name: fname}) do
    queryable
    |> select([m],
      {
        field(m, ^String.to_atom(gbfname)),
        max(field(m, ^String.to_atom(fname)))
      }
    )
    |> where([m], not is_nil(field(m, ^String.to_atom(gbfname))))
    |> group_by([m], field(m, ^String.to_atom(gbfname)))
  end

  # get dataset (dataset label and data) by date trunc, count agg values
  # params:
  #   - :date_trunc
  #   - granularity
  #   - chart's group by field name
  #   - chart dataset record

  defp select_dataset(:date_trunc, :day, queryable, gbfname, %ChartDataset{func: "count", field_name: fname}) do
    queryable
    |> select([m],
      {
        type(
          fragment("date_trunc('day', ?)", field(m, ^String.to_atom(gbfname))),
          :naive_datetime
        ),
        count(field(m, ^String.to_atom(fname)))
      }
    )
    |> where([m],
      not is_nil(fragment("date_trunc('day', ?)", field(m, ^String.to_atom(gbfname))))
    )
    |> group_by([m],
      fragment("date_trunc('day', ?)", field(m, ^String.to_atom(gbfname)))
    )
  end

  defp select_dataset(:date_trunc, :week, queryable, gbfname, %ChartDataset{func: "count", field_name: fname}) do
    queryable
    |> select([m],
      {
        type(
          fragment("date_trunc('week', ?)", field(m, ^String.to_atom(gbfname))),
          :naive_datetime
        ),
        count(field(m, ^String.to_atom(fname)))
      }
    )
    |> where([m],
      not is_nil(fragment("date_trunc('week', ?)", field(m, ^String.to_atom(gbfname))))
    )
    |> group_by([m],
      fragment("date_trunc('week', ?)", field(m, ^String.to_atom(gbfname)))
    )
  end

  defp select_dataset(:date_trunc, :month, queryable, gbfname, %ChartDataset{func: "count", field_name: fname}) do
    queryable
    |> select([m],
      {
        type(
          fragment("date_trunc('month', ?)", field(m, ^String.to_atom(gbfname))),
          :naive_datetime
        ),
        count(field(m, ^String.to_atom(fname)))
      }
    )
    |> where([m],
      not is_nil(fragment("date_trunc('month', ?)", field(m, ^String.to_atom(gbfname))))
    )
    |> group_by([m],
      fragment("date_trunc('month', ?)", field(m, ^String.to_atom(gbfname)))
    )
  end

  defp select_dataset(:date_trunc, :year, queryable, gbfname, %ChartDataset{func: "count", field_name: fname}) do
    queryable
    |> select([m],
      {
        type(
          fragment("date_trunc('year', ?)", field(m, ^String.to_atom(gbfname))),
          :naive_datetime
        ),
        count(field(m, ^String.to_atom(fname)))
      }
    )
    |> where([m],
      not is_nil(fragment("date_trunc('year', ?)", field(m, ^String.to_atom(gbfname))))
    )
    |> group_by([m],
      fragment("date_trunc('year', ?)", field(m, ^String.to_atom(gbfname)))
    )
  end

  # get dataset (dataset label and data) by date trunc, avg agg values
  # params:
  #   - :date_trunc
  #   - granularity
  #   - chart's group by field name
  #   - chart dataset record

  defp select_dataset(:date_trunc, :day, queryable, gbfname, %ChartDataset{func: "avg", field_name: fname}) do
    queryable
    |> select([m],
      {
        type(
          fragment("date_trunc('day', ?)", field(m, ^String.to_atom(gbfname))),
          :naive_datetime
        ),
        avg(field(m, ^String.to_atom(fname)))
      }
    )
    |> where([m],
      not is_nil(fragment("date_trunc('day', ?)", field(m, ^String.to_atom(gbfname))))
    )
    |> group_by([m],
      fragment("date_trunc('day', ?)", field(m, ^String.to_atom(gbfname)))
    )
  end

  defp select_dataset(:date_trunc, :week, queryable, gbfname, %ChartDataset{func: "avg", field_name: fname}) do
    queryable
    |> select([m],
      {
        type(
          fragment("date_trunc('week', ?)", field(m, ^String.to_atom(gbfname))),
          :naive_datetime
        ),
        avg(field(m, ^String.to_atom(fname)))
      }
    )
    |> where([m],
      not is_nil(fragment("date_trunc('week', ?)", field(m, ^String.to_atom(gbfname))))
    )
    |> group_by([m],
      fragment("date_trunc('week', ?)", field(m, ^String.to_atom(gbfname)))
    )
  end

  defp select_dataset(:date_trunc, :month, queryable, gbfname, %ChartDataset{func: "avg", field_name: fname}) do
    queryable
    |> select([m],
      {
        type(
          fragment("date_trunc('month', ?)", field(m, ^String.to_atom(gbfname))),
          :naive_datetime
        ),
        avg(field(m, ^String.to_atom(fname)))
      }
    )
    |> where([m],
      not is_nil(fragment("date_trunc('month', ?)", field(m, ^String.to_atom(gbfname))))
    )
    |> group_by([m],
      fragment("date_trunc('month', ?)", field(m, ^String.to_atom(gbfname)))
    )
  end

  defp select_dataset(:date_trunc, :year, queryable, gbfname, %ChartDataset{func: "avg", field_name: fname}) do
    queryable
    |> select([m],
      {
        type(
          fragment("date_trunc('year', ?)", field(m, ^String.to_atom(gbfname))),
          :naive_datetime
        ),
        avg(field(m, ^String.to_atom(fname)))
      }
    )
    |> where([m],
      not is_nil(fragment("date_trunc('year', ?)", field(m, ^String.to_atom(gbfname))))
    )
    |> group_by([m],
      fragment("date_trunc('year', ?)", field(m, ^String.to_atom(gbfname)))
    )
  end

  # get dataset (dataset label and data) by date trunc, min agg values
  # params:
  #   - :date_trunc
  #   - granularity
  #   - chart's group by field name
  #   - chart dataset record

  defp select_dataset(:date_trunc, :day, queryable, gbfname, %ChartDataset{func: "min", field_name: fname}) do
    queryable
    |> select([m],
      {
        type(
          fragment("date_trunc('day', ?)", field(m, ^String.to_atom(gbfname))),
          :naive_datetime
        ),
        min(field(m, ^String.to_atom(fname)))
      }
    )
    |> where([m],
      not is_nil(fragment("date_trunc('day', ?)", field(m, ^String.to_atom(gbfname))))
    )
    |> group_by([m],
      fragment("date_trunc('day', ?)", field(m, ^String.to_atom(gbfname)))
    )
  end

  defp select_dataset(:date_trunc, :week, queryable, gbfname, %ChartDataset{func: "min", field_name: fname}) do
    queryable
    |> select([m],
      {
        type(
          fragment("date_trunc('week', ?)", field(m, ^String.to_atom(gbfname))),
          :naive_datetime
        ),
        min(field(m, ^String.to_atom(fname)))
      }
    )
    |> where([m],
      not is_nil(fragment("date_trunc('week', ?)", field(m, ^String.to_atom(gbfname))))
    )
    |> group_by([m],
      fragment("date_trunc('week', ?)", field(m, ^String.to_atom(gbfname)))
    )
  end

  defp select_dataset(:date_trunc, :month, queryable, gbfname, %ChartDataset{func: "min", field_name: fname}) do
    queryable
    |> select([m],
      {
        type(
          fragment("date_trunc('month', ?)", field(m, ^String.to_atom(gbfname))),
          :naive_datetime
        ),
        min(field(m, ^String.to_atom(fname)))
      }
    )
    |> where([m],
      not is_nil(fragment("date_trunc('month', ?)", field(m, ^String.to_atom(gbfname))))
    )
    |> group_by([m],
      fragment("date_trunc('month', ?)", field(m, ^String.to_atom(gbfname)))
    )
  end

  defp select_dataset(:date_trunc, :year, queryable, gbfname, %ChartDataset{func: "min", field_name: fname}) do
    queryable
    |> select([m],
      {
        type(
          fragment("date_trunc('year', ?)", field(m, ^String.to_atom(gbfname))),
          :naive_datetime
        ),
        min(field(m, ^String.to_atom(fname)))
      }
    )
    |> where([m],
      not is_nil(fragment("date_trunc('year', ?)", field(m, ^String.to_atom(gbfname))))
    )
    |> group_by([m],
      fragment("date_trunc('year', ?)", field(m, ^String.to_atom(gbfname)))
    )
  end

  # get dataset (dataset label and data) by date trunc, max agg values
  # params:
  #   - :date_trunc
  #   - granularity
  #   - chart's group by field name
  #   - chart dataset record

  defp select_dataset(:date_trunc, :day, queryable, gbfname, %ChartDataset{func: "max", field_name: fname}) do
    queryable
    |> select([m],
      {
        type(
          fragment("date_trunc('day', ?)", field(m, ^String.to_atom(gbfname))),
          :naive_datetime
        ),
        max(field(m, ^String.to_atom(fname)))
      }
    )
    |> where([m],
      not is_nil(fragment("date_trunc('day', ?)", field(m, ^String.to_atom(gbfname))))
    )
    |> group_by([m],
      fragment("date_trunc('day', ?)", field(m, ^String.to_atom(gbfname)))
    )
  end

  defp select_dataset(:date_trunc, :week, queryable, gbfname, %ChartDataset{func: "max", field_name: fname}) do
    queryable
    |> select([m],
      {
        type(
          fragment("date_trunc('week', ?)", field(m, ^String.to_atom(gbfname))),
          :naive_datetime
        ),
        max(field(m, ^String.to_atom(fname)))
      }
    )
    |> where([m],
      not is_nil(fragment("date_trunc('week', ?)", field(m, ^String.to_atom(gbfname))))
    )
    |> group_by([m],
      fragment("date_trunc('week', ?)", field(m, ^String.to_atom(gbfname)))
    )
  end

  defp select_dataset(:date_trunc, :month, queryable, gbfname, %ChartDataset{func: "max", field_name: fname}) do
    queryable
    |> select([m],
      {
        type(
          fragment("date_trunc('month', ?)", field(m, ^String.to_atom(gbfname))),
          :naive_datetime
        ),
        max(field(m, ^String.to_atom(fname)))
      }
    )
    |> where([m],
      not is_nil(fragment("date_trunc('month', ?)", field(m, ^String.to_atom(gbfname))))
    )
    |> group_by([m],
      fragment("date_trunc('month', ?)", field(m, ^String.to_atom(gbfname)))
    )
  end

  defp select_dataset(:date_trunc, :year, queryable, gbfname, %ChartDataset{func: "max", field_name: fname}) do
    queryable
    |> select([m],
      {
        type(
          fragment("date_trunc('year', ?)", field(m, ^String.to_atom(gbfname))),
          :naive_datetime
        ),
        max(field(m, ^String.to_atom(fname)))
      }
    )
    |> where([m],
      not is_nil(fragment("date_trunc('year', ?)", field(m, ^String.to_atom(gbfname))))
    )
    |> group_by([m],
      fragment("date_trunc('year', ?)", field(m, ^String.to_atom(gbfname)))
    )
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

    case !is_nil(starts) and !is_nil(ends) do
      false ->
        nil

      true ->
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
