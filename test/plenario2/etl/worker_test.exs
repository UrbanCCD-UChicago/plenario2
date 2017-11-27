defmodule Plenario2.Etl.WorkerTest do
  alias Plenario2.Actions.{
    DataSetActions,
    DataSetFieldActions,
    DataSetConstraintActions,
    MetaActions,
    UserActions,
    VirtualPointFieldActions,
    VirtualDateFieldActions
  }

  alias Plenario2.Etl.Worker
  alias Plenario2.Schemas.Meta
  alias Postgrex.Result

  import Ecto.Adapters.SQL, only: [query!: 3]
  import Mock

  use Plenario2.DataCase

  require HTTPoison

  @stage_name "Chicago Tree Trimming"
  @stage_source "https://example.com/chicago-tree-trimming"

  setup do
    {:ok, user} = UserActions.create("user", "password", "email@example.com")

    {:ok, meta} =
      MetaActions.create(
        @stage_name,
        user.id,
        @stage_source
      )

    {:ok, pk} = DataSetFieldActions.create(meta.id, "pk", "integer")
    DataSetFieldActions.create(meta.id, "datetime", "timestamptz")
    DataSetFieldActions.create(meta.id, "location", "text")
    DataSetFieldActions.create(meta.id, "data", "text")
    DataSetFieldActions.make_primary_key(pk)
    VirtualPointFieldActions.create_from_loc(meta.id, "location")
    DataSetActions.create_dataset_table(meta)

    %{
      meta: meta,
      table_name: Meta.get_dataset_table_name(meta)
    }
  end

  @doc """
  This helper function replaces the call to HTTPoison.get! made by a worker
  process. It returns a generic set of csv data to ingest.

  ## Example

    iex> mock_csv_data_request("http://doesnt_matter.com")
    %HTTPoison.Response{body: "csv data..."}

  """
  def mock_csv_data_request(_) do
    %HTTPoison.Response{
      body: """
      pk, datetime, location, data
      1, 2017-01-01T00:00:00, (-42, 81), crackers
      2, 2017-02-02T00:00:00, (-43, 82), and
      3, 2017-03-03T00:00:00, (-44, 84), cheese
      """
    }
  end

  test "Worker downloads file to correct location", context do
    with_mock HTTPoison, get!: &mock_csv_data_request/1 do
      %{meta: meta, table_name: table_name} = context

      state =
        Worker.download(%{
          meta: meta,
          table_name: table_name
        })

      assert state[:worker_downloaded_file_path] === "/tmp/#{table_name}.csv"
      assert File.exists?("/tmp/#{table_name}.csv")
    end
  end

  @insert_rows [
    [1, "2017-01-01T00:00:00", "(0, 1)", "crackers"],
    [2, "2017-01-02T00:00:00", "(0, 2)", "and"],
    [3, "2017-01-03T00:00:00", "(0, 3)", "cheese"]
  ]

  @upsert_rows [
    [1, "2017-01-01T00:00:00", "(0, 1)", "biscuits"],
    [4, "2017-01-04T00:00:00", "(0, 4)", "gromit"]
  ]

  test "inserts a set of new records", context do
    %{meta: meta, table_name: table_name} = context

    state =
      Worker.upsert!(self(), %{
        meta: meta,
        table_name: table_name,
        rows: @insert_rows
      })

    %Postgrex.Result{rows: rows} = query!(Plenario2.Repo, "select * from #{table_name}", [])
    assert Enum.sort(rows) === @insert_rows
  end

  test "inserts and updates new and existing records", context do
    # %{meta: meta, table_name: table_name} = context

    # apply(Worker, :upsert!, [%{
    #   meta: meta,
    #   table_name: table_name,
    #   rows: @insert_rows
    # }])

    # apply(Worker, :upsert!, [%{
    #   meta: meta,
    #   table_name: table_name,
    #   rows: @insert_rows
    # }])

    # %Postgrex.Result{rows: rows} = query!(Plenario2.Repo, @select_query, [])
    # expected_rows = Enum.take(rows, -1)
    # assert expected_rows === [[1, "I changed!", 9999]]
  end

  describe "load/1" do
    test "ingests the sample data" do
      # state
      # |> Worker.download()
      # |> Worker.stage()
      # |> Worker.load()
    end
  end
end
