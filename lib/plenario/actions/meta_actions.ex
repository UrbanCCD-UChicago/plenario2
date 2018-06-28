defmodule Plenario.Actions.MetaActions do
  @moduledoc """
  This module provides a high level API for interacting with the
  Meta schema -- creating, updating, getting, ...
  """

  require Logger

  import Ecto.Query

  alias Plenario.{Repo, ModelRegistry}
  alias Plenario.Schemas.{Meta, User}
  alias Plenario.Changesets.MetaChangesets
  alias Plenario.Queries.MetaQueries

  alias Plenario.Actions.{
    DataSetActions,
    DataSetFieldActions,
    VirtualDateFieldActions,
    VirtualPointFieldActions,
    MetaActions
  }

  @type ok_instance :: {:ok, Meta.t} | {:error, Ecto.Changeset.t()}

  @doc """
  This is a convenience function for generating empty changesets to more
  easily construct forms in Phoenix templates.
  """
  @spec new() :: Ecto.Changeset.t()
  def new(), do: MetaChangesets.new()

  @doc """
  Create a new instance of Meta in the database.
  """
  @spec create(name :: String.t(), user :: User | integer, source_url :: String.t(), source_type :: String.t()) :: ok_instance
  def create(name, %User{} = user, source_url, source_type),
    do: create(name, user.id, source_url, source_type)
  def create(name, user, source_url, source_type) do
    params = %{
      name: name,
      user_id: user,
      source_url: source_url,
      source_type: source_type
    }
    MetaChangesets.create(params)
    |> Repo.insert()
  end

  @doc """
  This is a convenience function for generating prepopulated changesets
  to more easily construct change forms in Phoenix templates.
  """
  @spec edit(instance :: Meta) :: Ecto.Changeset.t()
  def edit(instance), do: MetaChangesets.update(instance, %{})

  @doc """
  Updates a given Meta's attributes.

  If the Meta instance's state field is not "new" though, this
  will error out -- you cannot update an active Meta.
  """
  @spec update(instance :: Meta, opts :: Keyword.t()) :: ok_instance
  def update(instance, opts \\ []) do
    params = Enum.into(opts, %{})
    MetaChangesets.update(instance, params)
    |> Repo.update()
  end

  @doc """
  Convenience function for updating a Meta's bbox attribute.
  """
  @spec update_bbox(meta :: Meta, bbox :: Geo.Polygon) :: ok_instance
  def update_bbox(meta, bbox), do: MetaActions.update(meta, bbox: bbox)

  @doc """
  Convenience function for updating a Meta's time_range attribute.
  """
  @spec update_time_range(Meta.t, Plenario.TsRange.t) :: ok_instance
  def update_time_range(%Meta{} = meta, %Plenario.TsRange{} = range), do: MetaActions.update(meta, time_range: range)

  @doc """
  Convenience function for updating a Meta's latest_import attribute.
  """
  @spec update_latest_import(meta :: Meta.t, timestamp :: NaiveDateTime.t) :: ok_instance
  def update_latest_import(meta, timestamp) do
    Logger.info("updating meta '#{meta.name}' latest import to '#{timestamp}'")
    MetaActions.update(meta, latest_import: timestamp)
  end

  @doc """
  Convenience function for updating a Meta's next_import attribute.
  """
  @spec update_next_import(meta :: Meta.t) :: ok_instance
  def update_next_import(%Meta{refresh_rate: nil, refresh_interval: nil} = meta), do: {:ok, meta}
  def update_next_import(%Meta{refresh_rate: rate, refresh_interval: interval} = meta) do
    next_import =
      case meta.next_import do
        nil -> NaiveDateTime.utc_now()
        _ -> meta.next_import
      end

    diff = abs(Timex.diff(next_import, NaiveDateTime.utc_now(), String.to_atom(rate)))
    Logger.info("import diff is #{diff} #{rate}")
    next_import =
      case diff > interval do
        true ->
          Logger.info("next_import has fallen out of sync -- using `now` as the base to increment", ansi_color: "red")
          NaiveDateTime.utc_now()

        false -> next_import
      end

    shifted = Timex.shift(next_import, [{String.to_atom(rate), interval}]) |> Timex.to_naive_datetime()
    Logger.info("updating `next_import` to #{inspect(shifted)} for meta #{inspect(meta.name)}")

    MetaActions.update(meta, next_import: shifted)
  end

  @doc """
  Marks the given Meta as needs approval in the database.
  """
  @spec submit_for_approval(meta :: Meta) :: ok_instance
  def submit_for_approval(meta) do
    Meta.submit_for_approval(meta)
    |> Repo.update()
  end

  @doc """
  Marks the given Meta as approved in the database. It then brings up the
  needed table, functions and triggers for the data set.

  If everything succeeds, this returns {:ok, Meta}; if something goes wrong
  while bringing up the data set, it returns {:error, "message"} and calls
  `mark_erred`.
  """
  @spec approve(meta :: Meta) :: {:ok, Meta} | {:error, String.t()}
  def approve(meta) do
    {:ok, meta} =
      Meta.approve(meta)
      |> Repo.update()

    try do
      DataSetActions.up!(meta)
      {:ok, meta}
    rescue
      e in Postgrex.Error ->
        DataSetActions.down!(meta)
        mark_erred(meta)
        {:error, e.message}
    end
  end

  @doc """
  Marks the given Meta as new in the database.
  """
  @spec disapprove(meta :: Meta) :: ok_instance
  def disapprove(meta) do
    Meta.disapprove(meta)
    |> Repo.update()
  end

  @doc """
  Marks the given Meta as ready in the database and sets the Meta's first_import
  date to the current timestamp.
  """
  @spec mark_first_import(meta :: Meta) :: ok_instance
  def mark_first_import(meta) do
    {:ok, _} = MetaChangesets.update(meta, %{first_import: NaiveDateTime.utc_now()})
    |> Repo.update()

    meta = get(meta.id)
    Meta.mark_first_import(meta)
    |> Repo.update()
  end

  @doc """
  Marks the given Meta as erred in the database.
  """
  @spec mark_erred(meta :: Meta) :: ok_instance
  def mark_erred(meta) do
    Meta.mark_erred(meta)
    |> Repo.update()
  end

  @doc """
  Marks the given Meta as ready after having erred in the database.
  """
  @spec mark_fixed(meta :: Meta) :: ok_instance
  def mark_fixed(meta) do
    Meta.mark_fixed(meta)
    |> Repo.update()
  end

  @doc """
  Gets a list of Meta from the database.

  This can be optionally filtered using the opts. See
  MetaQueries.handle_opts for more details.
  """
  @spec list(opts :: Keyword.t() | nil) :: list(Meta)
  def list(opts \\ []) do
    MetaQueries.list()
    |> MetaQueries.handle_opts(opts)
    |> Repo.all()
  end

  @doc """
  Gets a single Meta from the database.

  This can be optionally filtered using the opts. See
  MetaQueries.handle_opts for more details.
  """
  @spec get(identifier :: String.t() | integer, opts :: Keyword.t() | nil) :: Meta | nil
  def get(identifier, opts \\ []) do
    MetaQueries.get(identifier)
    |> MetaQueries.handle_opts(opts)
    |> Repo.one()
  end

  @doc """
  Gets a list of the field names for a given Meta.
  """
  def get_column_names(meta) do
    for f <- DataSetFieldActions.list(for_meta: meta), do: f.name
  end

  @doc """
  Selects all dates in the data set's table and finds the minimum and maximum
  values. From those values, it creates a TsRange.
  """
  @spec compute_time_range!(Meta.t) :: Plenario.TsRange.t
  def compute_time_range!(meta) do
    timestamp_fields =
      DataSetFieldActions.list(for_meta: meta)
      |> Enum.filter(& &1.type == "timestamp")
      |> Enum.map(& &1.name)
    virtual_dates =
      VirtualDateFieldActions.list(for_meta: meta)
      |> Enum.map(& &1.name)

    fields =
      timestamp_fields ++ virtual_dates
      |> Enum.join("\", \"")

    query = """
    SELECT
      MIN(l) AS lower,
      MAX(g) AS upper
    FROM (
      SELECT
        LEAST("#{fields}") AS l,
        GREATEST("#{fields}") AS g
      FROM
        "#{meta.table_name}_view"
    ) AS subq;
    """

    %Postgrex.Result{rows: [[lower, upper]]} = Repo.query!(query)
    Plenario.TsRange.new(lower, upper)
  end

  @doc """
  Selects all points in the data set's table and finds the minimum and maximum
  values. From those values, it creates a Polygon.
  """
  @spec compute_bbox!(Meta.t) :: Geo.Polygon.t
  def compute_bbox!(meta) do
    fields =
      VirtualPointFieldActions.list(for_meta: meta)
      |> Enum.map(& &1.name)

    stx = Enum.map(fields, & "st_x(\"#{&1}\")") |> Enum.join(", ")
    sty = Enum.map(fields, & "st_y(\"#{&1}\")") |> Enum.join(", ")

    query = """
    SELECT
      MIN(subq.min_x) AS min_x,
      MIN(subq.min_y) AS min_y,
      MAX(subq.max_x) AS max_x,
      MAX(subq.max_y) AS max_y
    FROM (
      SELECT
        LEAST(#{stx}) AS min_x,
        LEAST(#{sty}) AS min_y,
        GREATEST(#{stx}) AS max_x,
        GREATEST(#{sty}) AS max_y
      FROM
        "#{meta.table_name}_view"
    ) AS subq
    """

    %Postgrex.Result{rows: [[min_x, min_y, max_x, max_y]]} = Repo.query!(query)
    %Geo.Polygon{coordinates: [[
      {max_y, min_x},
      {min_y, min_x},
      {min_y, max_x},
      {max_y, max_x},
      {max_y, min_x}
    ]],
    srid: 4326}
  end

  def dump_bbox(%Meta{bbox: nil}), do: nil
  def dump_bbox(%Meta{bbox: %Geo.Polygon{} = bbox}) do
    coords = List.first(bbox.coordinates)
    coord_strings = for {lat, lon} <- coords, do: "[#{lat},#{lon}]"
    "[#{Enum.join(coord_strings, ", ")}]"
  end

  def get_record_count(meta) do
    model = ModelRegistry.lookup(meta.slug)
    Repo.one(from m in model, select: fragment("count(*)"))
  end

  def get_agg_data(%Meta{} = meta) do
    fields = DataSetFieldActions.list(for_meta: meta)
    points = VirtualPointFieldActions.list(for_meta: meta)
    dates = VirtualDateFieldActions.list(for_meta: meta)

    point_ref_ids =
      points
      |> Enum.map(& [&1.loc_field_id, &1.lat_field_id, &1.lon_field_id])
      |> List.flatten()
      |> Enum.reject(& is_nil(&1))
      |> Enum.uniq()

    date_ref_ids =
      dates
      |> Enum.map(& [
        &1.year_field_id, &1.month_field_id, &1.day_field_id,
        &1.hour_field_id, &1.minute_field_id, &1.second_field_id
      ])
      |> List.flatten()
      |> Enum.reject(& is_nil(&1))
      |> Enum.uniq()

    numerical_fields =
      fields
      |> Enum.filter(& &1.type in ["integer", "float"])
      |> Enum.reject(& &1.id in point_ref_ids)
      |> Enum.reject(& &1.id in date_ref_ids)
      |> Enum.map(& String.to_atom(&1.name))

    timestamp_fields =
      fields
      |> Enum.filter(& &1.type == "timestamp")
      |> Enum.map(& String.to_atom(&1.name))

    boolean_fields =
      fields
      |> Enum.filter(& &1.type == "boolean")
      |> Enum.map(& String.to_atom(&1.name))

    # if no timestamp fields, then take the first virtual date
    timestamp_fields =
      case timestamp_fields do
        [] ->
          Enum.map(dates, & String.to_atom(&1.name))
        _ ->
          timestamp_fields
      end
    timestamp = List.first(timestamp_fields)

    cond do
      # if numerical fields then render a line chart
      length(numerical_fields) > 0 ->
        agg_numerical(meta, numerical_fields, timestamp)

      # else if boolean fields, render a doughnut chart
      length(boolean_fields) > 0 ->
        agg_boolean(meta, boolean_fields, timestamp)

      # else render a map with pins for locations
      true ->
        point_field = Enum.map(points, & &1.name) |> List.first()
        agg_points(meta, point_field)
    end
  end

  defp agg_numerical(meta, numerical_fields, timestamp) do
    query =
      """
      SELECT
        DATE_TRUNC('month', "<%= timestamp %>") AS Timestamp
        <%= for f <- fields do %>
        , AVG("<%= f %>") AS "<%= f %>"
        <% end %>
      FROM
        "<%= view %>"
      GROUP BY
        Timestamp
      ORDER BY
        Timestamp ASC
      """
      |> EEx.eval_string([
        timestamp: timestamp,
        fields: numerical_fields,
        view: "#{meta.table_name}_view"
      ], trim: true)

    %Postgrex.Result{columns: cols, rows: rows} = Repo.query!(query)

    labels = for [{ymd, {h, m, s, _}} | _] <- rows, do: NaiveDateTime.from_erl!({ymd, {h, m, s}})

    rows = for [_ | row] <- rows, do: row
    [_ | cols] = cols
    data =
      Enum.with_index(cols)
      |> Enum.map(fn {col, idx} ->
        row_data = for row <- rows, do: Enum.at(row, idx)
        {col, row_data}
      end)

    {:line, labels, data}
  end

  defp agg_boolean(meta, boolean_fields, timestamp) do
    query =
      """
      SELECT
        DATE_TRUNC('month', "<%= timestamp %>") AS Timestamp
        <%= for f <- fields do %>
        , SUM(CASE WHEN "<%= f %>" THEN 1 ELSE 0 END) AS "<%= f %>: Yes"
        , SUM(CASE WHEN "<%= f %>" THEN 0 ELSE 1 END) AS "<%= f %>: No"
        <% end %>
      FROM
        "<%= view %>"
      GROUP BY
        Timestamp
      ORDER BY
        Timestamp ASC;
      """
      |> EEx.eval_string([
        timestamp: timestamp,
        fields: boolean_fields,
        view: "#{meta.table_name}_view"
      ], trim: true)

    %Postgrex.Result{columns: cols, rows: rows} = Repo.query!(query)

    labels = for [{ymd, {h, m, s, _}} | _] <- rows, do: NaiveDateTime.from_erl!({ymd, {h, m, s}})

    rows = for [_ | row] <- rows, do: row
    [_ | cols] = cols
    data =
      Enum.with_index(cols)
      |> Enum.map(fn {col, idx} ->
        row_data = for row <- rows, do: Enum.at(row, idx)
        {col, row_data}
      end)

    {:line, labels, data}
  end

  defp agg_points(meta, point_field) do
    query =
      """
      SELECT DISTINCT "<%= field %>"
      FROM "<%= view %>"
      """
      |> EEx.eval_string([
        field: point_field,
        view: "#{meta.table_name}_view"
      ], trim: true)

    %Postgrex.Result{rows: rows} = Repo.query!(query)

    coords = Enum.map(rows, fn row ->
      [%Geo.Point{coordinates: {lon, lat}}] = row
      {lat, lon}
    end)

    {:map, "Locations", coords}
  end
end
