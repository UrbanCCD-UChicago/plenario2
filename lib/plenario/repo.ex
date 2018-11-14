defmodule Plenario.Repo do
  use Ecto.Repo,
    otp_app: :plenario,
    adapter: Ecto.Adapters.Postgres

  alias Plenario.{
    DataSet,
    DataSetActions,
    Field,
    FieldActions,
    Repo,
    VirtualDate,
    VirtualDateActions,
    VirtualPoint,
    VirtualPointActions
  }

  ##
  #   UP

  @up_dirname             Path.join(["db-actions", "up"])
  @create_table           Path.join([@up_dirname, "create-table.sql.eex"])
  @create_view            Path.join([@up_dirname, "create-view.sql.eex"])
  @create_gin_index       Path.join([@up_dirname, "create-gin-index.sql.eex"])
  @create_gist_index      Path.join([@up_dirname, "create-gist-index.sql.eex"])
  @create_tsvector_index  Path.join([@up_dirname, "create-tsvector-index.sql.eex"])

  @doc """
  Brings the data set's table, view and indexes up.
  """
  def up!(%DataSet{id: id}) do
    # get the data set and its fields
    ds = DataSetActions.get!(id, with_fields: true)
    points = VirtualPointActions.list(for_data_set: ds, with_fields: true)
    dates = VirtualDateActions.list(for_data_set: ds, with_fields: true)

    # segment fields by type
    text_fields = Enum.filter(ds.fields, & &1.type == "text")
    boolean_fields = Enum.filter(ds.fields, & &1.type == "boolean")
    integer_fields = Enum.filter(ds.fields, & &1.type == "integer")
    float_fields = Enum.filter(ds.fields, & &1.type == "float")
    timestamp_fields = Enum.filter(ds.fields, & &1.type == "timestamp")
    geometry_fields = Enum.filter(ds.fields, & &1.type == "geometry")
    jsonb_fields = Enum.filter(ds.fields, & &1.type == "jsonb")

    # make lists of index-typed fields
    gin_bindings =
      (boolean_fields ++ integer_fields ++ float_fields ++ timestamp_fields ++ dates)
      |> Enum.map(fn f ->
        type =
          case f do
            %Field{} -> "f"
            %VirtualDate{} -> "vd"
          end
        [type: type, id: f.id, name: f.col_name, view_name: ds.view_name]
      end)

    gist_bindings =
      (geometry_fields ++ points)
      |> Enum.map(fn f ->
        type =
          case f do
            %Field{} -> "f"
            %VirtualPoint{} -> "vp"
          end
        [type: type, id: f.id, name: f.col_name, view_name: ds.view_name]
      end)

    tsvector_bindings =
      text_fields
      |> Enum.map(& [type: "f", id: &1.id, name: &1.col_name, view_name: ds.view_name])

    # bring everything up in a transaction
    Repo.transaction(fn ->
      create_table(ds.table_name, ds.fields)
      create_view(ds.table_name, ds.view_name, text_fields, boolean_fields, integer_fields, float_fields, timestamp_fields, geometry_fields, jsonb_fields, dates, points)
      create_indexes(@create_gin_index, gin_bindings)
      create_indexes(@create_gist_index, gist_bindings)
      create_indexes(@create_tsvector_index, tsvector_bindings)
    end)

    :ok
  end

  defp create_table(table_name, fields) do
    fmt_sql(@create_table, table_name: table_name, fields: fields, len_fields: length(fields))
    |> Repo.query!()
  end

  defp create_view(table_name, view_name, text, boolean, integer, float, timestamp, geometry, jsonb, vdates, vpoints) do
    fmt_sql(@create_view,
      table_name: table_name,
      view_name: view_name,
      text_fields: text,
      boolean_fields: boolean,
      integer_fields: integer,
      float_fields: float,
      timestamp_fields: timestamp,
      geometry_fields: geometry,
      jsonb_fields: jsonb,
      virtual_dates: vdates,
      virtual_points: vpoints,
      len_text: length(text)
    )
    |> Repo.query!()
  end

  defp create_indexes(template, bindings) do
    Enum.each(bindings, fn b ->
      fmt_sql(template, b)
      |> Repo.query!()
    end)
  end

  ##
  #   DOWN

  @down_dirname Path.join(["db-actions", "down"])
  @drop_table   Path.join([@down_dirname, "drop-table.sql.eex"])

  @doc """
  Cascade drops the data set's table -- drops all downstream entities.
  """
  def down!(%DataSet{id: id}) do
    data_set = DataSetActions.get!(id)

    {:ok, _} = Repo.transaction(fn ->
      drop_table(data_set)
    end)

    :ok
  end

  defp drop_table(%DataSet{table_name: table_name}) do
    fmt_sql(@drop_table, table_name: table_name)
    |> Repo.query!()
  end

  ##
  #   ETL

  @etl_timeout 1000 * 60 * 10

  @etl_dirname        Path.join(["db-actions", "etl"])
  @create_temp_table  Path.join([@etl_dirname, "create-temp-table.sql.eex"])
  @truncate_table     Path.join([@etl_dirname, "truncate-table.sql.eex"])
  @copy_to_temp       Path.join([@etl_dirname, "copy-to-temp.sql.eex"])
  @copy_to_table      Path.join([@etl_dirname, "copy-to-table.sql.eex"])
  @upsert_as_select   Path.join([@etl_dirname, "upsert-as-select.sql.eex"])
  @insert_as_select   Path.join([@etl_dirname, "insert-as-select.sql.eex"])
  @refresh_view       Path.join([@etl_dirname, "refresh-view.sql.eex"])

  @doc """
  ETL for a JSON web resource.

  Copies the source document as one big jsonb field to a temp table,
  truncates the permanent table, inserts as select from temp table,
  refreshes view, drops temp table, and then finally commits.
  """
  def etl!(%DataSet{socrata?: false, src_type: "json", id: id}, path) do
    data_set = DataSetActions.get!(id)

    {:ok, _} = Repo.transaction(fn ->
      create_temp_table(data_set)
      stream_file(data_set, path)
      truncate_table(data_set)
      insert_as_select(data_set)
      refresh_view(data_set)
    end, timeout: @etl_timeout)

    :ok
  end

  @doc """
  ETL for C/TSV web resource.

  Truncates the permanent table, copies the source document to
  the permament table, refreshes the view and then commits.
  """
  def etl!(%DataSet{socrata?: false, id: id}, path) do
    data_set = DataSetActions.get!(id)

    {:ok, _} = Repo.transaction(fn ->
      truncate_table(data_set)
      stream_file(data_set, path)
      refresh_view(data_set)
    end, timeout: @etl_timeout)

    :ok
  end

  @doc """
  ETL for the initial load of a Socrata resource.

  Copies the source document as one big jsonb field to a temp table,
  inserts as select from temp table, refreshes view, drops temp
  table, and then finally commits.
  """
  def etl!(%DataSet{socrata?: true, latest_import: nil, id: id}, path) do
    data_set = DataSetActions.get!(id)

    {:ok, _} = Repo.transaction(fn ->
      create_temp_table(data_set)
      stream_file(data_set, path)
      insert_as_select(data_set)
      refresh_view(data_set)
    end, timeout: @etl_timeout)

    :ok
  end

  @doc """
  ETL for refreshed Socrata resources.

  Copies the source document as one big jsonb field to a temp table,
  upserts as select from temp table, refreshes view, drops temp
  table, and then finally commits.
  """
  def etl!(%DataSet{socrata?: true, id: id}, path) do
    data_set = DataSetActions.get!(id)

    {:ok, _} = Repo.transaction(fn ->
      create_temp_table(data_set)
      stream_file(data_set, path)
      upsert_as_select(data_set)
      refresh_view(data_set)
    end, timeout: @etl_timeout)

    :ok
  end

  # helpers

  defp create_temp_table(%DataSet{temp_name: temp_name}) do
    fmt_sql(@create_temp_table, temp_name: temp_name)
    |> Repo.query!()
  end

  defp truncate_table(%DataSet{table_name: table_name}) do
    fmt_sql(@truncate_table, table_name: table_name)
    |> Repo.query!()
  end

  defp stream_file(%DataSet{src_type: "json", temp_name: temp_name}, path) do
    copy_cmd = fmt_sql(@copy_to_temp, temp_name: temp_name)
    sql_stream = Ecto.Adapters.SQL.stream(Repo, copy_cmd)

    Stream.resource(
      fn -> File.open!(path) end,
      fn fh ->
        case IO.read(fh, :line) do
          data when is_binary(data) ->
            {:ok, stream} = StringIO.open(data)
            iostream = IO.binstream(stream, :line)
            Repo.transaction(fn -> Enum.into(iostream, sql_stream) end, timeout: :infinity)
            {[], fh}

          _ ->
            {:halt, fh}
        end
      end,
      fn fh -> File.close(fh) end
    )
    |> Stream.run()
  end

  defp stream_file(%DataSet{table_name: table_name}, path) do
    # get headers
    header_line =
      File.stream!(path, [:utf8])
      |> Enum.take(1)
      |> List.first()
      |> String.trim()

    headers =
      Regex.split(~r/,(?=(?:[^"]*"[^"]*")*[^"]*$)/, header_line)
      |> Enum.map(& String.trim(&1, "\""))
      |> Enum.join("\", \"")

    # init sql stream
    copy_cmd = fmt_sql(@copy_to_table, table_name: table_name, headers: headers)
    sql_stream = Ecto.Adapters.SQL.stream(Repo, copy_cmd)

    # init file stream
    file_stream = File.stream!(path, [:utf8])

    # stream file as stdin
    Repo.transaction(fn ->
      Enum.into(file_stream, sql_stream)
    end, timeout: :infinity)
  end

  defp upsert_as_select(%DataSet{id: id, temp_name: temp_name, table_name: table_name}) do
    fields =
      FieldActions.list(for_data_set: id)
      |> Enum.map(& &1.col_name)

    fmt_sql(@upsert_as_select,
      temp_name: temp_name,
      table_name: table_name,
      fields: fields,
      len_fields: length(fields)
    )
    |> Repo.query!()
  end

  defp insert_as_select(%DataSet{id: id, temp_name: temp_name, table_name: table_name}),
    do: run_as_select(@insert_as_select, id, temp_name, table_name)

  defp run_as_select(template, id, temp_name, table_name) do
    fields =
      FieldActions.list(for_data_set: id)
      |> Enum.map(& &1.col_name)

    fmt_sql(template,
      temp_name: temp_name,
      table_name: table_name,
      fields: fields,
      len_fields: length(fields)
    )
    |> Repo.query!()
  end

  defp refresh_view(%DataSet{view_name: view_name}) do
    fmt_sql(@refresh_view, view_name: view_name)
    |> Repo.query!()
  end

  ##
  #   UNIVERSAL HELPERS

  defp fmt_sql(template, bindings) do
    Path.join([:code.priv_dir(:plenario), template])
    |> EEx.eval_file(bindings, trim: true)
  end
end
