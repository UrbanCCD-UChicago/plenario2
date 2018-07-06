defmodule Plenario.Actions.DataSetActions do
  require Logger

  alias Plenario.Repo

  alias Plenario.Actions.{
    MetaActions,
    DataSetFieldActions,
    VirtualDateFieldActions,
    VirtualPointFieldActions
  }

  alias Plenario.Schemas.Meta

  # up!

  @create_table "db-actions/up/create-table.sql.eex"
  @create_view "db-actions/up/create-view.sql.eex"
  @create_index "db-actions/up/create-index.sql.eex"

  def up!(%Meta{id: meta_id}), do: up!(meta_id)
  def up!(meta_id) do
    meta = MetaActions.get(meta_id)
    fields = DataSetFieldActions.list(for_meta: meta)
    virtual_dates = VirtualDateFieldActions.list(for_meta: meta, with_fields: true)
    virtual_points = VirtualPointFieldActions.list(for_meta: meta, with_fields: true)

    table_name = meta.table_name
    view_name = "#{table_name}_view"

    boolean_fields = Enum.filter(fields, & &1.type == "boolean") |> Enum.map(& &1.name)
    integer_fields = Enum.filter(fields, & &1.type == "integer") |> Enum.map(& &1.name)
    float_fields = Enum.filter(fields, & &1.type == "float") |> Enum.map(& &1.name)
    timestamp_fields = Enum.filter(fields, & &1.type == "timestamp") |> Enum.map(& &1.name)

    index_fields =
      boolean_fields ++
      integer_fields ++
      float_fields ++
      timestamp_fields ++
      Enum.map(virtual_dates, & &1.name)

    gist_index_fields = Enum.map(virtual_points, & &1.name)

    Repo.transaction fn ->
      execute! @create_table,
        table_name: table_name,
        fields: fields

      execute! @create_view,
        table_name: table_name,
        view_name: view_name,
        boolean_fields: boolean_fields,
        integer_fields: integer_fields,
        float_fields: float_fields,
        timestamp_fields: timestamp_fields,
        virtual_dates: virtual_dates,
        virtual_points: virtual_points

      Enum.each(index_fields, fn field ->
        execute! @create_index,
          view_name: view_name,
          field: field,
          using: false
      end)

      Enum.each(gist_index_fields, fn field ->
        execute! @create_index,
          view_name: view_name,
          field: field,
          using: "GIST"
      end)
    end

    :ok
  end

  # down!

  @drop_table "db-actions/down/drop-table.sql.eex"

  def down!(%Meta{id: meta_id}), do: down!(meta_id)
  def down!(meta_id) do
    meta = MetaActions.get(meta_id)
    Repo.transaction fn ->
      execute! @drop_table, table_name: meta.table_name
    end

    :ok
  end

  # etl!

  @truncate_table "db-actions/etl/truncate-table.sql.eex"
  @copy "db-actions/etl/copy.sql.eex"
  @refresh_view "db-actions/etl/refresh-view.sql.eex"

  def etl!(%Meta{id: meta_id}, download_path), do: etl!(meta_id, download_path)
  def etl!(meta_id, download_path) do
    meta = MetaActions.get(meta_id)

    table_name = meta.table_name
    view_name = "#{table_name}_view"

    delimiter = if meta.source_type == "csv", do: ",", else: "\t"
    header_line =
      File.stream!(download_path, [:utf8])
      |> Enum.take(1)
      |> List.first()
      |> String.trim()
    headers =
      Regex.split(~r/,(?=(?:[^"]*"[^"]*")*[^"]*$)/, header_line)
      |> Enum.map(& String.trim(&1, "\""))
    path = Path.join(:code.priv_dir(:plenario), @copy)
    cmd = EEx.eval_file(path, [table_name: table_name, headers: headers, delimiter: delimiter], trim: true)
    sql_stream = Ecto.Adapters.SQL.stream(Repo, cmd)
    file_stream = File.stream!(download_path, [:utf8])

    Repo.transaction fn ->
      execute! @truncate_table, table_name: table_name

      Repo.transaction(fn -> Enum.into(file_stream, sql_stream) end)

      execute! @refresh_view, view_name: view_name
    end

    :ok
  end

  # helpers

  defp execute!(template, bindings) do
    Path.join([:code.priv_dir(:plenario), template])
    |> EEx.eval_file(bindings, trim: true)
    |> Repo.query!()
  end
end
