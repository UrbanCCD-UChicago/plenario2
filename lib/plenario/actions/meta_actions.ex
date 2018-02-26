defmodule Plenario.Actions.MetaActions do
  @moduledoc """
  This module provides a high level API for interacting with the
  Meta schema -- creating, updating, getting, ...
  """

  import Ecto.Query

  import Plenario.Queries.Utils

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

  @type ok_instance :: {:ok, Meta} | {:error, Ecto.Changeset.t()}

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
  @spec update_time_range(meta :: Meta, lower :: DateTime, upper :: DateTime) :: ok_instance
  def update_time_range(meta, lower, upper), do: MetaActions.update(meta, time_range: [lower, upper])

  @doc """
  Convenience function for updating a Meta's latest_import attribute.
  """
  @spec update_latest_import(meta :: Meta, timestamp :: DateTime) :: ok_instance
  def update_latest_import(meta, timestamp), do: MetaActions.update(meta, latest_import: timestamp)

  @doc """
  Convenience function for updating a Meta's next_import attribute.
  """
  @spec update_next_import(meta :: Meta) :: ok_instance
  def update_next_import(%Meta{refresh_rate: nil, refresh_interval: nil} = meta), do: {:ok, meta}
  def update_next_import(%Meta{refresh_rate: rate, refresh_interval: interval} = meta) do
    current =
      case meta.next_import do
        nil -> DateTime.utc_now()
        _ -> meta.next_import
      end

    shifted = Timex.shift(current, [{String.to_atom(rate), interval}])
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
        {:error, e.postgres.message}
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
    {:ok, _} = MetaChangesets.update(meta, %{first_import: DateTime.utc_now()})
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
    fields = DataSetFieldActions.list(for_meta: meta)
    field_names = for f <- fields, do: f.name

    field_names
  end

  @doc """
  Selects all dates in the data set's table and finds the minimum and maximum
  values. From those values, it creates a TsTzRange.
  """
  @spec compute_time_range!(meta :: Meta) :: {DateTime, DateTime}
  def compute_time_range!(meta) do
    dsfs =
      DataSetFieldActions.list(for_meta: meta)
      |> Enum.filter(fn field -> field.type == "timestamptz" end)
    vdfs = VirtualDateFieldActions.list(for_meta: meta)
    all_timestamp_fields = dsfs ++ vdfs

    field_names = for field <- all_timestamp_fields do
      field.name
    end

    query = """
    SELECT "#{Enum.join(field_names, "\", \"")}"
    FROM "#{meta.table_name}";
    """
    {:ok, result} = Ecto.Adapters.SQL.query(Repo, query)

    erl_dates = List.flatten(result.rows)
    datetimes =
      for {{y, m, d}, {h, mm, s, _}} <- erl_dates do
        {:ok, ndt} = NaiveDateTime.from_erl({{y, m, d}, {h, mm, s}})
        {:ok, dt} = DateTime.from_naive(ndt, "Etc/UTC")
        dt
      end
    sorted = Enum.sort(datetimes, fn one, two -> DateTime.compare(one, two) == :gt end)

    upper = List.first(sorted)
    lower = List.last(sorted)

    {lower, upper}
  end

  @doc """
  Selects all points in the data set's table and finds the minimum and maximum
  values. From those values, it creates a Polygon.
  """
  @spec compute_bbox!(meta :: Meta) :: Geo.Polygon
  def compute_bbox!(meta) do
    dsfs =
      DataSetFieldActions.list(for_meta: meta)
      |> Enum.filter(fn field -> field.type == "geometry" end)
    vpfs = VirtualPointFieldActions.list(for_meta: meta)
    all_point_fields = dsfs ++ vpfs

    field_names =
      for field <- all_point_fields do
        field.name
      end

    query = """
    SELECT "#{Enum.join(field_names, "\", \"")}"
    FROM "#{meta.table_name}";
    """
    {:ok, result} = Ecto.Adapters.SQL.query(Repo, query)

    points =
      List.flatten(result.rows)
      |> Enum.filter(fn pt -> pt != nil end)
    xs =
      for pt <- points do
        %{coordinates: {_, x}} = pt
        x
      end
    ys =
      for pt <- points do
        %{coordinates: {y, _}} = pt
        y
      end
    sorted_xs = Enum.sort(xs)
    sorted_ys = Enum.sort(ys)

    max_x = List.first(sorted_xs)
    min_x = List.last(sorted_xs)
    max_y = List.first(sorted_ys)
    min_y = List.last(sorted_ys)

    %Geo.Polygon{coordinates: [[
      {max_x, min_y}, {min_x, min_y},
      {min_x, max_y}, {max_x, max_y},
      {max_x, min_y}]],
    srid: 4326}
  end

  def guess_field_types!(meta) do
    %HTTPoison.Response{body: body} = HTTPoison.get!(meta.source_url)
    path = "/tmp/#{meta.slug}.#{meta.source_type}"
    File.write!(path, body)

    cnt = 1_001
    first_thousand =
      case meta.source_type do
        "csv" -> parse_csv!(path, cnt)
        "tsv" -> parse_tsv!(path, cnt)
        "json" -> parse_json!(path, cnt)
        "shp" -> parse_shapefile!(path, cnt)
      end

    guesses =
      for row <- first_thousand do
        for {key, value} <- row do
          cond do
            check_boolean(value) -> {key, "boolean"}
            check_integer(value) -> {key, "integer"}
            check_float(value) -> {key, "float"}
            check_date(value) -> {key, "timestamptz"}
            check_json(value) -> {key, "jsonb"}
            true -> {key, "text"}
          end
        end
      end
      |> List.flatten()

    counts =
      Enum.reduce(guesses, %{}, fn x, acc -> Map.update(acc, x, 1, &(&1 + 1)) end)
      |> Enum.into([])

    maxes =
      Enum.reduce(counts, %{}, fn {{k, _}, c}, acc ->
        curr = Map.get(acc, k, 0)
        if c > curr do
          Map.update(acc, k, c, &(&1 - &1 + c))
        else
          acc
        end
      end)

    col_types =
      Enum.reduce(maxes, %{}, fn {col, max_c}, acc ->
        {{_, type}, _} = Enum.find(counts, fn {{k, _}, c} -> "#{k}" == "#{col}" and c == max_c end)
        Map.merge(acc, %{col => type})
      end)

    col_types
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

  def get_agg_data(meta, starts, ends) do
    model = ModelRegistry.lookup(meta.slug)
    fields = DataSetFieldActions.list(for_meta: meta)

    number_fields =
      fields
      |> Enum.filter(fn f -> f.type in ["float", "integer"] end)
      |> Enum.filter(fn f -> not String.ends_with?(String.downcase(f.name), ["id"]) end)
      |> Enum.filter(fn f -> not String.starts_with?(String.downcase(f.name), ["lat", "lon", "loc"]) end)
      |> Enum.take(5)
    len_fields = length(number_fields)

    ts_field =
      fields
      |> Enum.filter(fn f -> f.type == "timestamptz" end)
      |> List.first()
    ts_field =
      case ts_field == nil do
        false -> ts_field
        true ->
          VirtualDateFieldActions.list(for_meta: meta)
          |> List.first()
      end

    query =
      """
      SELECT
        date_trunc('month', "<%= ts_field.name %>") as Timestamp,
        <%= for {f, idx} <- Enum.with_index(number_fields) do %>
        avg("<%= f.name %>") as "<%= f.name %>"<%= if idx < len_fields do %>,<% end %>
        <% end %>
      FROM
        "<%= table_name %>"
      GROUP BY
        Timestamp
      ORDER BY
        Timestamp DESC
      ;
      """
    sql = EEx.eval_string(
      query,
      [ts_field: ts_field, number_fields: number_fields,
      len_fields: len_fields - 1, table_name: meta.table_name],
      trim: true
    )
    case Ecto.Adapters.SQL.query(Repo, sql) do
      {:ok, results} ->
        labels =
          for [{{y, mo, d}, {h, mi, s, _}} | _] <- results.rows do
            case NaiveDateTime.from_erl({{y, mo, d}, {h, mi, s}}) do
              {:ok, ndt} -> ndt
              _ -> ""
            end
          end
        [_ | cols] = results.columns
        IO.inspect(labels)
        IO.inspect(cols)

        rows =
          for [_ | row] <- results.rows do
            row
          end
        IO.inspect(rows)

        data =
          for idx <- 0..len_fields do
            col = Enum.at(cols, idx)
            values =
              for row <- rows do
                Enum.at(row, idx)
              end
            {col, values}
          end
          |> Enum.filter(fn {c, _} -> c != nil end)

        %{
          labels: labels,
          data: data
        }

      {:error, whatever} ->
        %{
          labels: ["Uno", "Dos", "Tres", "Quattro", "Cinco", "Sies"],
          data: [{"Foo", [1,5,4,2,5,6]}, {"Bar", [2,3,1,5,6,5]}, {"Baz", [4,3,4,7,8,2]}]
        }
    end
  end

  defp parse_csv!(filename, count) do
    File.stream!(filename)
    |> Enum.take(count)
    |> CSV.decode!(headers: true)
  end

  defp parse_tsv!(filename, count) do
    File.stream!(filename)
    |> Enum.take(count)
    |> CSV.decode!(headers: true, separator: ?\t)
  end

  defp parse_json!(filename, count) do
    File.read!(filename)
    |> Poison.decode!()
    |> Enum.take(count)
  end

  defp parse_shapefile!(_, _) do
    []
  end

  defp check_boolean(value), do: Regex.match?(~r/^t|true|f|false$/i, value)

  defp check_integer(value), do: Regex.match?(~r/^-?\d+$/, value)

  defp check_float(value), do: Regex.match?(~r/^-?\d+\.\d+$/, value)

  defp check_date(value), do: Regex.match?(~r/\d{2,4}-|\/\d{2}-|\/\d{2,4}(.\d{1,2}:\d{1,2}:\d{1,2})?/, value)

  defp check_json(value), do: Regex.match?(~r/^[[{].+[]}]$/, value)
end
