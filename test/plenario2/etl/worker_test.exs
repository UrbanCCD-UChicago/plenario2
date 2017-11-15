defmodule Plenario2.Etl.WorkerTest do
  alias Plenario2.Etl.Worker
  import Ecto.Adapters.SQL, only: [query!: 3]
  use Plenario2.DataCase

  @stage_name "test"
  @stage_source "http://insight.dev.schoolwires.com/HelpAssets/
  C2Assets/C2Files/C2ImportCalEventSample.csv"
  @stage_path "/tmp/#{@stage_name}.csv"

  test "Worker downloads file to correct location" do
    state =
      Worker.download(%{
        name: @stage_name,
        source_url: @stage_source
      })

    assert state[:worker_downloaded_file_path] === @stage_path
    assert File.exists?(@stage_path)
  end

  @stage_schema %{
    table: @stage_name,
    pk: "id",
    columns: ["foo", "bar"],
    fields: [
      foo: "text",
      bar: "integer"
    ]
  }

  @select_query "select * from #{@stage_schema[:table]}"

  test "Worker stages table correctly" do
    Worker.stage(@stage_schema)
    %Postgrex.Result{columns: columns, rows: rows} = query!(Plenario2.Repo, @select_query, [])

    assert columns === ["id" | @stage_schema[:columns]]
    assert rows === []
  end

  @insert_rows [
    ["hello", 1000],
    ["world", 2000],
    ["itsa me", 3000],
    ["mario", 4000]
  ]

  @insert_args [@stage_schema, @insert_rows]

  test "Worker inserts a chunk of rows" do
    Worker.stage(@stage_schema)
    apply(Worker, :upsert!, @insert_args)
    %Postgrex.Result{rows: rows} = query!(Plenario2.Repo, @select_query, [])

    expected_rows =
      @insert_rows
      |> Enum.reverse()
      |> Enum.with_index()
      |> Enum.map(fn row ->
           {[text, int], index} = row
           [index + 1, text, int]
         end)

    assert rows === expected_rows
  end

  @upsert_rows [[1, "I changed!", 9999]]
  @upsert_schema %{
    table: @stage_name,
    pk: "id",
    columns: ["id", "foo", "bar"]
  }

  @upsert_args [@upsert_schema, @upsert_rows]

  test "Worker inserts and updates a chunk of rows" do
    Worker.stage(@stage_schema)
    apply(Worker, :upsert!, @insert_args)
    apply(Worker, :upsert!, @upsert_args)
    %Postgrex.Result{rows: rows} = query!(Plenario2.Repo, @select_query, [])
    expected_rows = Enum.take(rows, -1)
    assert expected_rows === [[1, "I changed!", 9999]]
  end
end
