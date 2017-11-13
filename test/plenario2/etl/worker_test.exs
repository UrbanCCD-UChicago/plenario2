defmodule Plenario2.Etl.WorkerTest do
  alias Plenario2.Etl.Worker
  use ExUnit.Case

  @fixture_name "calendars"
  @fixture_source_url "http://insight.dev.schoolwires.com/HelpAssets/C2Assets/C2Files/C2ImportCalEventSample.csv"
  @fixture_tmp_path "/tmp/calendars.csv"

  test "Worker downloads file to correct location" do
    state = Worker.download(%{
      name: @fixture_name,
      source_url: @fixture_source_url
    })

    assert state[:worker_downloaded_file_path] === @fixture_tmp_path
    assert File.exists? @fixture_tmp_path
  end

  test "Worker stages table correctly" do
    Worker.stage(%{name: "hello", fields: [
      foo: "string",
      bar: "integer"
    ]})
  end
end