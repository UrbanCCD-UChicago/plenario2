defmodule Plenario.Actions.DataSetActions do
  @moduledoc false

  require Logger

  alias Plenario.Repo

  alias Plenario.Actions.{
    MetaActions,
    DataSetFieldActions,
    VirtualDateFieldActions,
    VirtualPointFieldActions
  }

  alias Plenario.Schemas.Meta

  @template_dir Path.join(:code.priv_dir(:plenario), "data-set-action-sql-templates")
  @up_dir Path.join(@template_dir, "up")
  @down_dir Path.join(@template_dir, "down")
  @etl_dir Path.join(@template_dir, "etl")

  @create_table Path.join(@up_dir, "create-table.sql.eex")
  @create_index Path.join(@up_dir, "create-index.sql.eex")
  @create_parse_points Path.join(@up_dir, "create-parse-points-trigger.sql.eex")
  @apply_parse_points Path.join(@up_dir, "apply-parse-points-trigger.sql.eex")
  @create_parse_timestamps Path.join(@up_dir, "create-parse-timestamps-trigger.sql.eex")
  @apply_parse_timestamps Path.join(@up_dir, "apply-parse-timestamps-trigger.sql.eex")

  @drop_table Path.join(@down_dir, "drop-table.sql.eex")

  @create_temp_table Path.join(@etl_dir, "create-temp-table.sql.eex")
  @copy_from_csv Path.join(@etl_dir, "copy-from-csv.sql.eex")
  @truncate Path.join(@etl_dir, "truncate.sql.eex")
  @copy_from_temp_table Path.join(@etl_dir, "copy-from-table.sql.eex")
  @drop_temp_table Path.join(@etl_dir, "drop-temp-table.sql.eex")

  def up!(%Meta{id: id}), do: up!(id)
  def up!(meta_id) do
    Logger.info("starting process to bring up data set table", meta_id: meta_id)

    meta = MetaActions.get(meta_id)
    fields = DataSetFieldActions.list(for_meta: meta)
    dates = VirtualDateFieldActions.list(for_meta: meta, with_fields: true)
    points = VirtualPointFieldActions.list(for_meta: meta, with_fields: true)

    len_fields = length(fields)
    table_name = meta.table_name

    Repo.transaction fn ->
      # bring up the table
      Logger.info("creating table #{inspect(table_name)}", meta_id: meta_id)
      execute!(@create_table, table_name: table_name, fields: fields, len_fields: len_fields, dates: dates, points: points)

      # index native timestamp fields
      fields
      |> Enum.filter(fn f -> f.type == "timestamptz" end)
      |> Enum.each(fn f ->
        Logger.info("adding an index to #{inspect(table_name)} for field #{f.name}", meta_id: meta_id)
        execute!(@create_index, table_name: table_name, field_name: f.name, using: nil)
      end)

      # index virtual dates
      Enum.each(dates, fn d ->
        Logger.info("adding an index to #{inspect(table_name)} for field #{d.name}", meta_id: meta_id)
        execute!(@create_index, table_name: table_name, field_name: d.name, using: nil)
      end)

      # index points
      Enum.each(points, fn p ->
        Logger.info("adding an index to #{inspect(table_name)} for field #{p.name}", meta_id: meta_id)
        execute!(@create_index, table_name: table_name, field_name: p.name, using: "GIST")
      end)

      # create parse timestamps trigger and apply it to the table
      if length(dates) > 0 do
        Logger.info("adding a trigger to #{inspect(table_name)} to parse timestamps", meta_id: meta_id)
        execute!(@create_parse_timestamps, table_name: table_name, dates: dates)
        execute!(@apply_parse_timestamps, table_name: table_name)
      end

      # create parse points trigger and apply it to the table
      if length(points) > 0 do
        Logger.info("adding a trigger to #{inspect(table_name)} to parse points", meta_id: meta_id)
        execute!(@create_parse_points, table_name: table_name, points: points)
        execute!(@apply_parse_points, table_name: table_name)
      end
    end

    Logger.info("data set table #{inspect(table_name)} fully brought up", meta_id: meta_id)

    :ok
  end

  def down!(%Meta{id: id}), do: down!(id)
  def down!(meta_id) do
    Logger.info("starting process to drop data set table", meta_id: meta_id)

    meta = MetaActions.get(meta_id)
    execute!(@drop_table, table_name: meta.table_name)

    Logger.info("data set table fully dropped", meta_id: meta_id)

    :ok
  end

  def etl!(%Meta{id: id}, path, opts), do: etl!(id, path, opts)
  def etl!(meta_id, path, opts) do
    opts = Keyword.merge([delimiter: ",", headers?: true], opts)

    Logger.info("starting native postgres etl process; path=#{inspect(path)}; opts=#{inspect(opts)}", meta_id: meta_id)

    meta = MetaActions.get(meta_id)
    fields = DataSetFieldActions.list(for_meta: meta)

    table_name = meta.table_name
    len_fields = length(fields)

    Repo.transaction fn ->
      # create a temp table for the data set
      Logger.info("creating a temp data table", meta_id: meta_id)
      execute!(@create_temp_table, table_name: table_name, fields: fields, len_fields: len_fields)

      # copy from the csv to the temp table
      Logger.info("copying data from csv #{inspect(path)} to temp table", meta_id: meta_id)
      execute!(@copy_from_csv, table_name: table_name, path: path, delimiter: opts[:delimiter], headers?: opts[:headers?])

      # truncate the existing table
      Logger.info("truncating exsiting data set table", meta_id: meta_id)
      execute!(@truncate, table_name: table_name)

      # copy from the temp table to the existing table
      Logger.info("copying data from temp to existing data set table", meta_id: meta_id)
      execute!(@copy_from_temp_table, table_name: table_name, fields: fields, len_fields: len_fields)

      # drop the temp table
      Logger.info("dropping the temp table", meta_id: meta_id)
      execute!(@drop_temp_table, table_name: table_name)
    end

    Logger.info("native postgres etl complete", meta_id: meta_id)

    :ok
  end

  defp execute!(template, bindings) do
    sql = EEx.eval_file(template, bindings, trim: true)
    Repo.query!(sql)
  end
end
