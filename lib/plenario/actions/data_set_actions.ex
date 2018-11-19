defmodule Plenario.DataSetActions do
  import Plenario.ActionUtils

  alias Plenario.{
    DataSet,
    DataSetQueries,
    FieldActions,
    Repo,
    VirtualDateActions,
    VirtualPointActions
  }

  # CRUD

  def list(opts \\ []) do
    DataSetQueries.list()
    |> DataSetQueries.handle_opts(opts)
    |> Repo.all()
  end

  def get(id, opts \\ []) do
    ds =
      DataSetQueries.get(id)
      |> DataSetQueries.handle_opts(opts)
      |> Repo.one()

    case ds do
      nil -> {:error, nil}
      _ -> {:ok, ds}
    end
  end

  def get!(id, opts \\ []) do
    DataSetQueries.get(id)
    |> DataSetQueries.handle_opts(opts)
    |> Repo.one!()
  end

  def create(params) do
    params =
      params_to_map(params)
      |> parse_relation(:user)

    DataSet.changeset(%DataSet{}, params)
    |> Repo.insert()
  end

  def update(ds, params) do
    params =
      params_to_map(params)
      |> parse_relation(:user)

    DataSet.changeset(ds, params)
    |> Repo.update()
  end

  def delete(ds), do: Repo.delete(ds)

  # Other Actions

  def compute_next_import!(%DataSet{refresh_rate: nil}, _), do: nil
  def compute_next_import!(%DataSet{refresh_interval: nil}, _), do: nil
  def compute_next_import!(%DataSet{refresh_interval: interval, refresh_rate: rate}, last) do
    Timex.shift(last, [{String.to_atom(interval), rate}])
    |> Timex.to_naive_datetime()
  end

  def compute_bbox!(%DataSet{} = ds) do
    field_names = get_geom_fields(ds)

    query = """
    SELECT st_envelope(#{field_names})
    FROM "#{ds.view_name}"
    """

    %Postgrex.Result{rows: [[bbox]], num_rows: 1} = Repo.query!(query)
    bbox
  end

  def compute_hull!(%DataSet{} = ds) do
    field_names = get_geom_fields(ds)

    query = """
    SELECT st_convexhull(#{field_names})
    FROM "#{ds.view_name}"
    """

    %Postgrex.Result{rows: [[hull]], num_rows: 1} = Repo.query!(query)
    hull
  end

  defp get_geom_fields(ds) do
    fields =
      FieldActions.list(for_data_set: ds)
      |> Enum.filter(& &1.type == "geometry")
      |> Enum.map(& &1.col_name)

    points =
      VirtualPointActions.list(for_data_set: ds)
      |> Enum.map(& &1.col_name)

    names =
      (fields ++ points)
      |> Enum.join("\", \"")

    case length((fields ++ points)) do
      1 -> "st_union(\"#{names}\")"
      _ -> "st_union(st_collect(\"#{names}\"))"
    end
  end

  def compute_time_range!(%DataSet{} = ds) do
    fields =
      FieldActions.list(for_data_set: ds)
      |> Enum.filter(& &1.type == "timestamp")
      |> Enum.map(& &1.col_name)

    dates =
      VirtualDateActions.list(for_data_set: ds)
      |> Enum.map(& &1.col_name)

    field_names =
      (fields ++ dates)
      |> Enum.join("\", \"")

    query = """
    SELECT
      MIN( LEAST("#{field_names}")) AS lower,
      MAX( GREATEST("#{field_names}")) AS upper
    FROM "#{ds.view_name}"
    """

    %Postgrex.Result{rows: [[lower, upper]], num_rows: 1} = Repo.query!(query)

    case is_nil(lower) or is_nil(upper) do
      true -> nil
      false -> Plenario.TsRange.new(lower, upper)
    end
  end

  def get_num_records!(%DataSet{} = ds) do
    query = """
    SELECT COUNT(*)
    FROM "#{ds.view_name}"
    """

    %Postgrex.Result{rows: [[count]], num_rows: 1} = Repo.query!(query)

    case count do
      0 -> nil
      _ -> count
    end
  end
end
