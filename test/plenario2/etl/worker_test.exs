defmodule Plenario2.Etl.WorkerTest do
  alias Plenario2.Etl.Worker
  alias Postgrex.Result
  import Ecto.Adapters.SQL, only: [query!: 3]
  use Plenario2.DataCase

  @stage_name "test"
  @stage_source "http://insight.dev.schoolwires.com/HelpAssets/C2Assets/C2Files/C2ImportCalEventSample.csv"
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
    columns: ["id", "foo", "bar"],
    fields: [
      id: "integer",
      foo: "text",
      bar: "integer"
    ]
  }

  @select_query "select * from #{@stage_schema[:table]}"

  describe "stage/1" do
    @stage_schema_no_pk %{@stage_schema | pk: nil, columns: ["foo", "bar"]}

    test "creates table without primary key" do
      Worker.stage(@stage_schema_no_pk)
      %Result{columns: columns} = query!(Plenario2.Repo, @select_query, [])

      assert columns === @stage_schema_no_pk[:columns]
    end

    test "creates table with primary key" do
      Worker.stage(@stage_schema)
      %Result{columns: columns} = query!(Plenario2.Repo, @select_query, [])

      assert columns === @stage_schema[:columns]
    end
  end

  @insert_rows [
    [1, "hello", 1000],
    [2, "world", 2000],
    [3, "itsa me", 3000],
    [4, "mario", 4000]
  ]

  @insert_args [@stage_schema, @insert_rows]

  describe "upsert/2" do
    setup do
      Worker.stage(@stage_schema)
    end

    test "inserts a set of new records" do
      apply(Worker, :upsert!, @insert_args)
      %Postgrex.Result{rows: rows} = query!(Plenario2.Repo, @select_query, [])
      assert Enum.sort(rows) === @insert_rows
    end

    @upsert_rows [[1, "I changed!", 9999]]
    @upsert_schema %{
      table: @stage_name,
      pk: {:id, "integer"},
      columns: ["id", "foo", "bar"]
    }

    @upsert_args [@upsert_schema, @upsert_rows]

    test "inserts and updates new and existing records" do
      apply(Worker, :upsert!, @insert_args)
      apply(Worker, :upsert!, @upsert_args)
      %Postgrex.Result{rows: rows} = query!(Plenario2.Repo, @select_query, [])
      expected_rows = Enum.take(rows, -1)
      assert expected_rows === [[1, "I changed!", 9999]]
    end
  end

  def state_fixture do
    columns = 
      File.stream!(@stage_path)
      |> CSV.decode!()
      |> Enum.take(1)

    %{
      table: @stage_name,
      source_url: @stage_source,
      pk: "event_title",
      columns: columns,
      fields: Enum.map(columns, fn column ->
        {String.to_atom(column), "text"}
      end)
    }
  end

  describe "load/1" do
    test "ingests the sample data" do
      state = state_fixture()

      state
      |> Worker.download()
      |> Worker.stage()
      |> Worker.load()
    end
  end
end
