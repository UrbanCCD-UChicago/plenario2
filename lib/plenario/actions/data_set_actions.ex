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
    meta = MetaActions.get(meta_id)
    fields = DataSetFieldActions.list(for_meta: meta)
    dates = VirtualDateFieldActions.list(for_meta: meta, with_fields: true)
    points = VirtualPointFieldActions.list(for_meta: meta, with_fields: true)

    len_fields = length(fields)
    table_name = meta.table_name

    Repo.transaction fn ->
      # bring up the table
      execute!(@create_table, table_name: table_name, fields: fields, len_fields: len_fields, dates: dates, points: points)

      # index native timestamp fields
      fields
      |> Enum.filter(fn f -> f.type == "timestamptz" end)
      |> Enum.each(fn f ->
        execute!(@create_index, table_name: table_name, field_name: f.name, using: nil)
      end)

      # index virtual dates
      Enum.each(dates, fn d ->
        execute!(@create_index, table_name: table_name, field_name: d.name, using: nil)
      end)

      # index points
      Enum.each(points, fn p ->
        execute!(@create_index, table_name: table_name, field_name: p.name, using: "GIST")
      end)

      # create parse timestamps trigger and apply it to the table
      if length(dates) > 0 do
        execute!(@create_parse_timestamps, table_name: table_name, dates: dates)
        execute!(@apply_parse_timestamps, table_name: table_name)
      end

      # create parse points trigger and apply it to the table
      if length(points) > 0 do
        execute!(@create_parse_points, table_name: table_name, points: points)
        execute!(@apply_parse_points, table_name: table_name)
      end
    end

    :ok
  end

  def down!(%Meta{id: id}), do: down!(id)
  def down!(meta_id) do
    meta = MetaActions.get(meta_id)
    execute!(@drop_table, table_name: meta.table_name)

    :ok
  end

  def etl!(%Meta{id: id}, path, opts), do: etl!(id, path, opts)
  def etl!(meta_id, path, opts) do
    opts = Keyword.merge([delimiter: ",", headers?: true], opts)

    meta = MetaActions.get(meta_id)
    fields = DataSetFieldActions.list(for_meta: meta)

    table_name = meta.table_name
    len_fields = length(fields)

    Repo.transaction fn ->
      execute!(@create_temp_table, table_name: table_name, fields: fields, len_fields: len_fields)
      execute!(@copy_from_csv, table_name: table_name, path: path, delimiter: opts[:delimiter], headers?: opts[:headers?])
      execute!(@truncate, table_name: table_name)
      execute!(@copy_from_temp_table, table_name: table_name, fields: fields, len_fields: len_fields)
      execute!(@drop_temp_table, table_name: table_name)
    end

    :ok
  end

  defp execute!(template, bindings) do
    sql = EEx.eval_file(template, bindings, trim: true)
    Repo.query!(sql)
  end
end
