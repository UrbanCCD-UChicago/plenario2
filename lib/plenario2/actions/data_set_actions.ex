defmodule Plenario2.Actions.DataSetActions do
  alias Plenario2.Actions.{DataSetConstraintActions, DataSetFieldActions, MetaActions, VirtualDateFieldActions, VirtualPointFieldActions}
  alias Plenario2.Repo

  def create_data_set_table(meta) do
    table_name = MetaActions.get_data_set_table_name(meta)

    # create table sql
    ds_fields = for f <- DataSetFieldActions.list_for_meta(meta), do: %{name: f.name, type: f.type, opts: f.opts}
    dt_fields = for f <- VirtualDateFieldActions.list_for_meta(meta), do: %{name: f.name, type: "TIMESTAMPTZ", opts: "DEFAULT NULL"}
    pt_fields = for f <- VirtualPointFieldActions.list_for_meta(meta), do: %{name: f.name, type: "GEOMETRY(POINT, #{meta.srid})", opts: "DEFAULT NULL"}
    fields = ds_fields ++ dt_fields ++ pt_fields

    create_table_sql = gen_sql_create_table(table_name, fields)

    # add constraint sql
    add_constraint_sqls = for c <- DataSetConstraintActions.list_for_meta(meta), do: gen_sql_add_constraint(table_name, c.constraint_name, c.field_names)

    # date function and trigger sql
    parse_date_func_name = "func_#{table_name}_parse_timestamp"
    parse_date_trigger_name = "trigger_#{table_name}_parse_timestamp"
    date_fields = VirtualDateFieldActions.list_for_meta(meta)

    parse_date_func_sql = gen_sql_create_parse_timestamp_function(meta.timezone)
    parse_date_trigger_func_sql = gen_sql_create_timestamp_trigger_function(parse_date_func_name, meta.timezone, date_fields)
    parse_date_trigger_sql = gen_sql_create_trigger(parse_date_trigger_name, table_name, parse_date_func_name)


    # point functions and trigger sql
    parse_point_func_name = "func_#{table_name}_parse_point"
    parse_point_trigger_name = "trigger_#{table_name}_parse_point"
    point_fields = VirtualPointFieldActions.list_for_meta(meta)

    parse_lat_long_func_sql = gen_sql_create_parse_long_lat_function(meta.srid)
    parse_location_func_sql = gen_sql_create_parse_location_function(meta.srid)
    parse_point_trigger_func_sql = gen_sql_create_point_trigger_function(parse_point_func_name, meta.srid, point_fields)
    parse_point_trigger_sql = gen_sql_create_trigger(parse_point_trigger_name, table_name, parse_point_func_name)

    # execute
    Ecto.Adapters.SQL.query!(Repo, create_table_sql)
    Enum.map(add_constraint_sqls, fn (sql) -> Ecto.Adapters.SQL.query!(Repo, sql) end)
    Ecto.Adapters.SQL.query!(Repo, parse_date_func_sql)
    Ecto.Adapters.SQL.query!(Repo, parse_date_trigger_func_sql)
    Ecto.Adapters.SQL.query!(Repo, parse_date_trigger_sql)
    Ecto.Adapters.SQL.query!(Repo, parse_lat_long_func_sql)
    Ecto.Adapters.SQL.query!(Repo, parse_location_func_sql)
    Ecto.Adapters.SQL.query!(Repo, parse_point_trigger_func_sql)
    Ecto.Adapters.SQL.query!(Repo, parse_point_trigger_sql)
  end

  def drop_data_set_table(meta) do
    table_name = MetaActions.get_data_set_table_name(meta)
    sql = gen_sql_drop_table(table_name)

    Ecto.Adapters.SQL.query!(Repo, sql)
  end

  ##
  # sql generation

  defp gen_sql_create_table(table_name, fields) do
    template = """
    CREATE TABLE IF NOT EXISTS <%= table_name %> (
      <% len_fields = length(fields) %>
      <%= for {f, i} <- Enum.with_index(fields) do %>
      <%= f.name %> <%= f.type %> <%= f.opts %><%= if i+1 < len_fields do %>,<% end %>
      <% end %>
    );
    """

    EEx.eval_string(template, [table_name: table_name, fields: fields], [trim: true])
  end

  defp gen_sql_drop_table(table_name) do
    template = """
    DROP TABLE IF EXISTS <%= table_name %>;
    """

    EEx.eval_string(template, [table_name: table_name], [trim: true])
  end

  defp gen_sql_add_constraint(table_name, constraint_name, field_names) do
    template = """
    ALTER TABLE <%= table_name %>
      ADD CONSTRAINT <%= constraint_name %> UNIQUE
      <% len_fields = length(field_names) %>
      (<%= for {f, i} <- Enum.with_index(field_names) do %><%= f %><% if i+1 < len_fields do %>,<% end %><% end %>);
    """

    EEx.eval_string(template, [table_name: table_name, constraint_name: constraint_name, field_names: field_names], [trim: true])
  end

  defp gen_sql_create_parse_timestamp_function(timezone) do
    template = """
    CREATE OR REPLACE FUNCTION
      parse_timestamp_<%= timezone %>(
        year INTEGER,
        month INTEGER,
        day INTEGER,
        hour INTEGER,
        minute INTEGER,
        second INTEGER
      )
    RETURNS TIMESTAMP WITH TIME ZONE AS $$

      SELECT make_timestamptz(
        year,
        (CASE WHEN month IS NULL THEN 1 ELSE month END),
        (CASE WHEN day IS NULL THEN 1 ELSE day END),
        (CASE WHEN hour IS NULL THEN 0 ELSE hour END),
        (CASE WHEN minute IS NULL THEN 0 ELSE minute END),
        (CASE WHEN second IS NULL THEN 0 ELSE second END),
        '<%= timezone %>'
      )

    $$
    LANGUAGE 'sql' IMMUTABLE;
    """

    EEx.eval_string(template, [timezone: timezone], [trim: true])
  end

  defp gen_sql_create_timestamp_trigger_function(function_name, timezone, fields) do
    template = """
    CREATE FUNCTION
      <%= function_name %>()
    RETURNS TRIGGER AS $$

      BEGIN
        <%= for f <- fields do %>
        new.<%= f.name %> := parse_timestamp_<%= timezone %>(
          new.<%= f.year_field %>,
          <%= if f.month_field do %>new.<%= f.month_field %><% else %>NULL<% end %>,
          <%= if f.day_field do %>new.<%= f.day_field %><% else %>NULL<% end %>,
          <%= if f.hour_field do %>new.<%= f.hour_field %><% else %>NULL<% end %>,
          <%= if f.minute_field do %>new.<%= f.minute_field %><% else %>NULL<% end %>,
          <%= if f.second_field do %>new.<%= f.second_field %><% else %>NULL<% end %>
        );
        <% end %>
        return new;
      END

    $$
    LANGUAGE 'plpgsql';
    """

    EEx.eval_string(template, [function_name: function_name, timezone: timezone, fields: fields], [trim: true])
  end

  defp gen_sql_create_parse_long_lat_function(srid) do
    template = """
    CREATE OR REPLACE FUNCTION
      parse_pt_long_lat_<%= srid %>(long FLOAT, lat FLOAT)
    RETURNS GEOMETRY(POINT, <%= srid %>) AS $$

      SELECT ST_PointFromText(
        'POINT(' || long || ' ' || lat || ')',
        <%= srid %>
      )

    $$
    LANGUAGE 'sql' IMMUTABLE;
    """

    EEx.eval_string(template, [srid: srid], [trim: true])
  end

  defp gen_sql_create_parse_location_function(srid) do
    template = """
    CREATE FUNCTION
      parse_pt_location_<%= srid %>(location TEXT)
    RETURNS GEOMETRY(POINT, <%= srid %>) AS $$

      SELECT ST_PointFromText(
        'POINT(' || subq.long || ' ' || subq.lat || ')',
        <%= srid %>
      )
      FROM (
        SELECT
          FLOAT8((REGEXP_MATCHES($1, '([+-]?\\d+\\.\\d+)[^\\d]*([+-]?\\d+\\.\\d+)'))[1]) AS long,
          FLOAT8((REGEXP_MATCHES($1, '([+-]?\\d+\\.\\d+)[^\\d]*([+-]?\\d+\\.\\d+)'))[2]) AS lat
      ) AS subq

    $$
    LANGUAGE 'sql' IMMUTABLE;
    """

    EEx.eval_string(template, [srid: srid], [trim: true])
  end

  defp gen_sql_create_point_trigger_function(function_name, srid, fields) do
    template = """
    CREATE FUNCTION
      <%= function_name %>()
    RETURNS TRIGGER AS $$

      BEGIN
        <%= for f <- fields do %>
        <%= if f.location_field do %>
        new.<%= f.name %> := parse_pt_location_<%= srid %>(new.<%= f.location_field %>);
        <% else %>
        new.<%= f.name %> := parse_pt_long_lat_<%= srid %>(new.<%= f.longitude_field %>, new.<%= f.latitude_field %>);
        <% end %>
        <% end %>
        return new;
      END

    $$
    LANGUAGE 'plpgsql';
    """

    EEx.eval_string(template, [function_name: function_name, srid: srid, fields: fields], [trim: true])
  end

  defp gen_sql_create_trigger(trigger_name, table_name, function_name) do
    template = """
    CREATE TRIGGER <%= trigger_name %>
      BEFORE INSERT ON <%= table_name %>
        FOR EACH ROW
          EXECUTE PROCEDURE <%= function_name %>();
    """

    EEx.eval_string(template, [trigger_name: trigger_name, table_name: table_name, function_name: function_name], [trim: true])
  end
end
