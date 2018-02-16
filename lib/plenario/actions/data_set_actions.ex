defmodule Plenario.Actions.DataSetActions do

  require Logger

  alias Plenario.Repo

  alias Plenario.Actions.{
    DataSetFieldActions,
    MetaActions,
    VirtualDateFieldActions,
    VirtualPointFieldActions
  }

  @template_dir "priv/data-set-action-sql-templates"

  def up!(meta) when not is_integer(meta), do: up!(meta.id)
  def up!(meta_id) when is_integer(meta_id) do
    meta = MetaActions.get(
      meta_id,
      with_fields: true,
      with_virtual_dates: true,
      with_virtual_points: true,
      with_constraints: true)

    # create the table with fields and constraints
    constraints = for uc <- meta.unique_constraints do
      field_names =
        DataSetFieldActions.list(by_ids: uc.field_ids)
        |> Enum.map(fn f -> f.name end)
        |> Enum.join("\", \"")
      {uc.name, field_names}
    end
    sql = create_table_sql(meta, constraints)
    execute_sql!(sql)

    # create timestamp parsing function and trigger
    sql = create_parse_timestamp_function_sql()
    execute_sql!(sql)

    vdfs = VirtualDateFieldActions.list(with_fields: true, for_meta: meta)
    fname = "parse_timetamps_#{meta.table_name}"
    sql = create_parse_timestamp_trigger_sql(fname, vdfs)
    execute_sql!(sql)

    trigger_name = "#{meta.table_name}_parse_timestamps"
    sql = create_trigger_sql(trigger_name, meta.table_name, fname)
    execute_sql!(sql)

    # create location and lat/lon parsing functions and triggers
    sql = create_parse_location_function_sql()
    execute_sql!(sql)
    sql = create_parse_lon_lat_function_sql()
    execute_sql!(sql)

    vpfs = VirtualPointFieldActions.list(with_fields: true, for_meta: meta)
    fname = "parse_points_#{meta.table_name}"
    sql = create_parse_points_trigger_sql(fname, vpfs)
    execute_sql!(sql)

    trigger_name = "#{meta.table_name}_parse_points"
    sql = create_trigger_sql(trigger_name, meta.table_name, fname)
    execute_sql!(sql)

    # done!
    :ok
  end

  def down!(meta) when not is_integer(meta), do: down!(meta.id)
  def down!(meta_id) when is_integer(meta_id) do
    meta = MetaActions.get(
      meta_id,
      with_fields: true,
      with_virtual_dates: true,
      with_virtual_points: true,
      with_constraints: true)

    # drop point functions and triggers
    trigger_name = "#{meta.table_name}_parse_points"
    sql = drop_trigger_sql(trigger_name, meta.table_name)
    execute_sql!(sql)

    function_name = "parse_points_#{meta.table_name}"
    sql = drop_function_sql(function_name)
    execute_sql!(sql)

    # drop timestamp functions and triggers
    trigger_name = "#{meta.table_name}_parse_timestamps"
    sql = drop_trigger_sql(trigger_name, meta.table_name)
    execute_sql!(sql)

    function_name = "parse_timetamps_#{meta.table_name}"
    sql = drop_function_sql(function_name)
    execute_sql!(sql)

    # drop table
    sql = drop_table_sql(meta.table_name)
    execute_sql!(sql)

    # done!
    :ok
  end

  defp create_table_sql(meta, constraints) do
    filename = "#{@template_dir}/create-table.sql.eex"
    sql = EEx.eval_file(filename, [meta: meta, constraints: constraints], trim: true)

    sql
  end

  defp create_parse_timestamp_function_sql() do
    filename = "#{@template_dir}/create-parse-timestamp-func.sql.eex"
    sql = EEx.eval_file(filename, [], trim: true)

    sql
  end

  defp create_parse_timestamp_trigger_sql(function_name, fields) do
    filename = "#{@template_dir}/create-parse-timestamp-trigger.sql.eex"
    sql = EEx.eval_file(
      filename,
      [function_name: function_name, fields: fields],
      trim: true)

    sql
  end

  defp create_parse_location_function_sql() do
    filename = "#{@template_dir}/create-parse-location-func.sql.eex"
    sql = EEx.eval_file(filename, [], trim: true)

    sql
  end

  defp create_parse_lon_lat_function_sql() do
    filename = "#{@template_dir}/create-parse-lat-lon-func.sql.eex"
    sql = EEx.eval_file(filename, [], trim: true)

    sql
  end

  defp create_parse_points_trigger_sql(function_name, fields) do
    filename = "#{@template_dir}/create-parse-points-trigger.sql.eex"
    sql = EEx.eval_file(
      filename,
      [function_name: function_name, fields: fields],
      trim: true)

    sql
  end

  defp create_trigger_sql(trigger_name, table_name, function_name) do
    filename = "#{@template_dir}/create-trigger.sql.eex"
    sql = EEx.eval_file(
      filename,
      [trigger_name: trigger_name, table_name: table_name, function_name: function_name],
      trim: true)

    sql
  end

  defp drop_table_sql(table_name) do
    filename = "#{@template_dir}/drop-table.sql.eex"
    sql = EEx.eval_file(filename, [table_name: table_name], trim: true)

    sql
  end

  defp drop_function_sql(function_name) do
    filename = "#{@template_dir}/drop-func.sql.eex"
    sql = EEx.eval_file(filename, [function_name: function_name], trim: true)

    sql
  end

  defp drop_trigger_sql(trigger_name, table_name) do
    filename = "#{@template_dir}/drop-trigger.sql.eex"
    sql = EEx.eval_file(
      filename,
      [trigger_name: trigger_name, table_name: table_name],
      trim: true)

    sql
  end

  defp execute_sql!(sql) do
    case Ecto.Adapters.SQL.query(Repo, sql) do
      {:ok, _} ->
        :ok

      {:error, error} ->
        Logger.error(error.postgres.message)
        Logger.error(sql)
        raise error
    end
  end
end
