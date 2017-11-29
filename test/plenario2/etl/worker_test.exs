defmodule Plenario2.Etl.WorkerTest do
  alias Plenario2.Actions.{
    DataSetActions,
    DataSetConstraintActions,
    DataSetFieldActions,
    EtlJobActions,
    MetaActions,
    UserActions,
    VirtualPointFieldActions,
  }

  alias Plenario2.Schemas.{
    DataSetDiff,
    Meta
  }

  alias Plenario2.Etl.Worker
  alias Plenario2.Repo

  import Ecto.Adapters.SQL, only: [query!: 3]
  import Mock

  require HTTPoison

  use Plenario2.DataCase

  @fixture_name "Chicago Tree Trimming"
  @fixture_source "https://example.com/chicago-tree-trimming"
  @fixture_columns ["pk", "datetime", "location", "data"]

  setup do
    {:ok, user} = UserActions.create("user", "password", "email@example.com")

    {:ok, meta} =
      MetaActions.create(
        @fixture_name,
        user.id,
        @fixture_source
      )

    {:ok, pk} = DataSetFieldActions.create(meta.id, "pk", "integer")
    DataSetFieldActions.create(meta.id, "datetime", "timestamptz")
    DataSetFieldActions.create(meta.id, "location", "text")
    DataSetFieldActions.create(meta.id, "data", "text")
    DataSetFieldActions.make_primary_key(pk)
    {:ok, constraint} = DataSetConstraintActions.create(meta.id, ["pk"])
    {:ok, job} = EtlJobActions.create(meta.id)
    VirtualPointFieldActions.create_from_loc(meta.id, "location")
    DataSetActions.create_dataset_table(meta)

    %{
      meta: meta,
      table_name: Meta.get_dataset_table_name(meta),
      constraint: constraint,
      job: job
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
      1, 2017-01-01T00:00:00, "(-42, 81)", crackers
      2, 2017-02-02T00:00:00, "(-43, 82)", and
      3, 2017-03-03T00:00:00, "(-44, 84)", cheese
      """
    }
  end

  test "download/1 downloads file to correct location", context do
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
    [1, "2017-01-01T00:00:00+00:00", "(0, 1)", "crackers"],
    [2, "2017-01-02T00:00:00+00:00", "(0, 2)", "and"],
    [3, "2017-01-03T00:00:00+00:00", "(0, 3)", "cheese"]
  ]

  @select_query "select pk, datetime, location, data from chicago_tree_trimming"

  test "upsert!/2 inserts a set of new records", context do
    %{meta: meta, table_name: table_name} = context

    Worker.upsert!(self(), %{
      meta: meta,
      table_name: table_name,
      rows: @insert_rows,
      columns: @fixture_columns
    })

    %Postgrex.Result{rows: rows} = query!(Plenario2.Repo, @select_query, [])

    assert [
      [1, {{2017, 1, 1}, {_, 0, 0, 0}}, "(0, 1)", "crackers"],
      [2, {{2017, 1, 2}, {_, 0, 0, 0}}, "(0, 2)", "and"],
      [3, {{2017, 1, 3}, {_, 0, 0, 0}}, "(0, 3)", "cheese"]
    ] = Enum.sort(rows)
  end

  @update_rows [
    [1, "2017-01-01T00:00:00", "(0, 1)", "biscuits"],
    [4, "2017-01-04T00:00:00", "(0, 4)", "gromit"]
  ]

  test "upsert!/2 inserts and updates new and existing records", context do
    %{meta: meta, table_name: table_name} = context

    Worker.upsert!(self(), %{
      meta: meta,
      table_name: table_name,
      rows: @insert_rows,
      columns: @fixture_columns
    })

    Worker.upsert!(self(), %{
      meta: meta,
      table_name: table_name,
      rows: @update_rows,
      columns: @fixture_columns
    })

    %Postgrex.Result{rows: rows} = query!(Plenario2.Repo, @select_query, [])

    # TODO(heyzoos) this assertion is done with a match because the timezone 
    # information seems to change depending on the host machine. Need to fix
    # whatever causes that behaviour
    assert [
      [1, {{2017, 1, 1}, {_, 0, 0, 0}}, "(0, 1)", "biscuits"],
      [2, {{2017, 1, 2}, {_, 0, 0, 0}}, "(0, 2)", "and"],
      [3, {{2017, 1, 3}, {_, 0, 0, 0}}, "(0, 3)", "cheese"],
      [4, {{2017, 1, 4}, {_, 0, 0, 0}}, "(0, 4)", "gromit"]
    ] = Enum.sort(rows)
  end

  test "contains!/2 retreives rows contained by upsert rows", context do
    %{meta: meta, table_name: table_name} = context

    Worker.upsert!(self(), %{
      meta: meta,
      table_name: table_name,
      rows: @insert_rows,
      columns: @fixture_columns
    })

    {_, %Postgrex.Result{rows: rows}} = Worker.contains!(self(), %{
      meta: meta,
      table_name: table_name,
      rows: @update_rows,
      columns: @fixture_columns
    })

    assert [[1, {{2017, 1, 1}, {_, 0, 0, 0}}, "(0, 1)", "crackers"]] = rows
  end

  test "load/1 ingests the sample data", context do
    with_mock HTTPoison, get!: &mock_csv_data_request/1 do
      state = context

      state
      |> Worker.download()
      |> Worker.load()
    end
  end

  describe "create_diffs/6" do
    test "creates diff database entries with arbitrary data", context do
      meta = MetaActions.get_by_pk_preload(context[:meta].id(), [:data_set_fields])
      columns = for field <- meta.data_set_fields() do field.name() end

      row1 = ["original", "original", "original"]
      row2 = ["original", "changed", "changed"]
      Worker.create_diffs(
        context[:meta].id(),
        context[:constraint].id(),
        context[:job].id(),
        columns,
        row1,
        row2
      )

      # ** (Postgrex.Error) ERROR 42703 (undefined_column): column d0.data_set_constraint_id does not exist
      diffs = Repo.all(DataSetDiff)
      # IO.inspect(diffs)
      assert Enum.count(diffs) === 2
    end
  end
end
