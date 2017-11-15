defmodule Plenario2.Etl.WorkerTest do
  alias Plenario2.Etl.Worker
  import Ecto.Adapters.SQL, only: [query!: 3]
  use Plenario2.DataCase

  @fixture_name "calendars"
  @fixture_source_url "http://insight.dev.schoolwires.com/HelpAssets/C2Assets/C2Files/C2ImportCalEventSample.csv"
  @fixture_tmp_path "/tmp/calendars.csv"

  test "Worker downloads file to correct location" do
    state =
      Worker.download(%{
        name: @fixture_name,
        source_url: @fixture_source_url
      })

    assert state[:worker_downloaded_file_path] === @fixture_tmp_path
    assert File.exists?(@fixture_tmp_path)
  end

  test "Worker stages table correctly" do
    Worker.stage(%{
      name: "hello",
      fields: [
        foo: "text",
        bar: "integer"
      ]
    })

    %Postgrex.Result{columns: columns, rows: rows} =
      query!(Plenario2.Repo, ~s{select * from "hello"}, [])

    assert columns === ["id", "foo", "bar"]
    assert rows === []
  end

  test "Worker inserts a chunk of rows" do
    Worker.stage(%{
      name: "hello",
      fields: [
        foo: "text",
        bar: "integer"
      ]
    })

    fixture_rows = [
      ["hello", 1000],
      ["world", 2000],
      ["itsa me", 3000],
      ["mario", 4000]
    ]

    Worker.upsert!(%{table: "hello", pk: "id", columns: ["foo", "bar"]}, fixture_rows)
    %Postgrex.Result{rows: rows} = query!(Plenario2.Repo, ~s{select * from "hello"}, [])

    expected_rows = fixture_rows
    |> Enum.reverse
    |> Enum.with_index
    |> Enum.map(fn row ->
      {[text, int], index} = row
      [index + 1, text, int]
    end)

    assert rows === expected_rows
  end
end
