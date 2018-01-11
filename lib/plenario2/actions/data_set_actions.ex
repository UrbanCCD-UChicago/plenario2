defmodule Plenario2.Actions.DataSetActions do
  @moduledoc """
  This module handles the database operations for working with
  tables that hold the data wrapped by the Metas.
  """

  require Logger

  alias Plenario2.Actions.{DataSetConstraintActions, DataSetFieldActions, MetaActions, VirtualDateFieldActions, VirtualPointFieldActions}
  alias Plenario2.Schemas.Meta
  alias Plenario2.Repo

  @template_dir "lib/plenario2/actions/templates/"

  @doc """
  Creates a database table, constraints, functions and triggers for a
  data set defined by its Meta and related schemas.
  """
  @spec create_data_set_table!(meta :: Meta) :: :ok
  def create_data_set_table!(meta) do
    # create table
    table_name = MetaActions.get_data_set_table_name(meta)

    ds_fields = for f <- DataSetFieldActions.list_for_meta(meta), do: %{name: f.name, type: f.type, opts: f.opts}
    dt_fields = for f <- VirtualDateFieldActions.list_for_meta(meta), do: %{name: f.name, type: "TIMESTAMPTZ", opts: "DEFAULT NULL"}
    pt_fields = for f <- VirtualPointFieldActions.list_for_meta(meta), do: %{name: f.name, type: "GEOMETRY(POINT, #{meta.srid})", opts: "DEFAULT NULL"}
    fields = ds_fields ++ dt_fields ++ pt_fields

    :ok = create_table!(table_name, fields)

    # add constraints
    Enum.map(DataSetConstraintActions.list_for_meta(meta), fn (c) ->
      :ok = add_constraint!(table_name, c.constraint_name, c.field_names)
    end)

    # date function and trigger sql
    parse_date_func_name = "func_#{table_name}_parse_timestamp"
    parse_date_trigger_name = "trigger_#{table_name}_parse_timestamp"
    date_fields = VirtualDateFieldActions.list_for_meta(meta)

    :ok = create_parse_timestamp_function!(meta.timezone)
    :ok = create_timestamp_trigger_function!(parse_date_func_name, meta.timezone, date_fields)
    :ok = create_trigger!(parse_date_trigger_name, table_name, parse_date_func_name)

    # point functions and trigger sql
    parse_point_func_name = "func_#{table_name}_parse_point"
    parse_point_trigger_name = "trigger_#{table_name}_parse_point"
    point_fields = VirtualPointFieldActions.list_for_meta(meta)

    :ok = create_parse_long_lat_function!(meta.srid)
    :ok = create_parse_location_function!(meta.srid)
    :ok = create_point_trigger_function!(parse_point_func_name, meta.srid, point_fields)
    :ok = create_trigger!(parse_point_trigger_name, table_name, parse_point_func_name)

    :ok
  end

  @doc """
  Drops the database table and all related database tooling for a data set
  """
  @spec drop_data_set_table!(meta :: Meta) :: :ok
  def drop_data_set_table!(meta) do
    table_name = MetaActions.get_data_set_table_name(meta)
    :ok = drop_table!(table_name)

    :ok
  end

  defp create_table!(table_name, fields) do
    sql =
      EEx.eval_file(
        "#{@template_dir}/create_table.sql.eex",
        [table_name: table_name, fields: fields],
        [trim: true]
      )

    case Ecto.Adapters.SQL.query(Repo, sql) do
      {:ok, _} ->
        Logger.info("successfully created table", table_name: table_name)
        :ok

      {:error, error} ->
        Logger.error("error creating table: #{error.postgres.message}", table_name: table_name)
        Logger.error(sql)
        raise error
    end
  end

  defp drop_table!(table_name) do
    sql =
      EEx.eval_file(
        "#{@template_dir}/drop_table.sql.eex",
        [table_name: table_name],
        [trim: true]
      )

    case Ecto.Adapters.SQL.query(Repo, sql) do
      {:ok, _} ->
        Logger.info("successfully dropped table", table_name: table_name)
        :ok

      {:error, error} ->
        Logger.error("error dropping table: #{error.postgres.message}", table_name: table_name)
        Logger.error(sql)
        raise error
    end
  end

  defp add_constraint!(table_name, constraint_name, field_names) do
    sql =
      EEx.eval_file(
        "#{@template_dir}/add_constraint.sql.eex",
        [table_name: table_name, constraint_name: constraint_name, field_names: field_names],
        [trim: true]
      )

    case Ecto.Adapters.SQL.query(Repo, sql) do
      {:ok, _} ->
        Logger.info("successfully added constraint `#{constraint_name}`", table_name: table_name)
        :ok

      {:error, error} ->
        Logger.error("error adding constraint: #{error.postgres.message}", table_name: table_name, constraint_name: constraint_name)
        Logger.error(sql)
        raise error
    end
  end

  defp create_parse_timestamp_function!(timezone) do
    sql =
      EEx.eval_file(
        "#{@template_dir}/create_parse_timestamp_function.sql.eex",
        [timezone: timezone],
        [trim: true]
      )

    case Ecto.Adapters.SQL.query(Repo, sql) do
      {:ok, _} ->
        Logger.info("successfully created parse timestamp function `#{timezone}`")
        :ok

      {:error, error} ->
        Logger.error("error creating parse timestamp function `#{timezone}`: #{error.postgres.message}")
        Logger.error(sql)
        raise error
    end
  end

  defp create_timestamp_trigger_function!(function_name, timezone, fields) do
    sql =
      EEx.eval_file(
        "#{@template_dir}/create_timestamp_trigger_function.sql.eex",
        [function_name: function_name, timezone: timezone, fields: fields],
        [trim: true]
      )

    case Ecto.Adapters.SQL.query(Repo, sql) do
      {:ok, _} ->
        Logger.info("successfully created parse timestamp function trigger `#{timezone}`")
        :ok

      {:error, error} ->
        Logger.error("error creating parse timestamp function trigger `#{timezone}`: #{error.postgres.message}")
        Logger.error(sql)
        raise error
    end
  end

  defp create_parse_long_lat_function!(srid) do
    sql =
      EEx.eval_file(
        "#{@template_dir}/create_parse_long_lat_function.sql.eex",
        [srid: srid],
        [trim: true]
      )

    case Ecto.Adapters.SQL.query(Repo, sql) do
      {:ok, _} ->
        Logger.info("successfully created parse long/lat function `#{srid}`")
        :ok

      {:error, error} ->
        Logger.error("error creating parse long/lat function `#{srid}`: #{error.postgres.message}")
        Logger.error(sql)
        raise error
    end
  end

  defp create_parse_location_function!(srid) do
    sql =
      EEx.eval_file(
        "#{@template_dir}/create_parse_location_function.sql.eex",
        [srid: srid],
        [trim: true]
      )

    case Ecto.Adapters.SQL.query(Repo, sql) do
      {:ok, _} ->
        Logger.info("successfully created parse location function `#{srid}`")
        :ok

      {:error, error} ->
        Logger.error("error creating parse location function `#{srid}`: #{error.postgres.message}")
        Logger.error(sql)
        raise error
    end
  end

  defp create_point_trigger_function!(function_name, srid, fields) do
    sql =
      EEx.eval_file(
        "#{@template_dir}/create_point_trigger_function.sql.eex",
        [function_name: function_name, srid: srid, fields: fields],
        [trim: true]
      )

    case Ecto.Adapters.SQL.query(Repo, sql) do
      {:ok, _} ->
        Logger.info("successfully created parse long/lat function trigger `#{srid}`")
        :ok

      {:error, error} ->
        Logger.error("error creating parse long/lat function trigger `#{srid}`: #{error.postgres.message}")
        Logger.error(sql)
        raise error
    end
  end

  defp create_trigger!(trigger_name, table_name, function_name) do
    sql =
      EEx.eval_file(
        "#{@template_dir}/create_trigger.sql.eex",
        [trigger_name: trigger_name, table_name: table_name, function_name: function_name],
        [trim: true]
      )

    case Ecto.Adapters.SQL.query(Repo, sql) do
      {:ok, _} ->
        Logger.info("successfully created trigger `#{trigger_name}`")
        :ok

      {:error, error} ->
        Logger.error("error creating trigger `#{trigger_name}`: #{error.postgres.message}")
        Logger.error(sql)
        raise error
    end
  end
end
