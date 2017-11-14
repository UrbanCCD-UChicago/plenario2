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

    assert columns === ["bar", "foo"]
    assert rows === []
  end
end
