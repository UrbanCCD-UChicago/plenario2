defmodule Plenario2Etl.WorkerTest do
  alias Plenario2.Actions.{
    DataSetActions,
    DataSetConstraintActions,
    DataSetFieldActions,
    EtlJobActions,
    MetaActions,
    VirtualPointFieldActions
  }

  alias Plenario2.Repo
  alias Plenario2.Schemas.DataSetDiff
  alias Plenario2Auth.UserActions
  alias Plenario2Etl.Worker

  import Ecto.Adapters.SQL, only: [query!: 3]
  import Mock

  require HTTPoison

  use Plenario2.DataCase

  @fixture_columns ["pk", "datetime", "location", "data"]
  @select_query "select #{Enum.join(@fixture_columns, ",")} from chicago_tree_trimming"
  @insert_rows [
    ["crackers", "2017-01-01T00:00:00+00:00", "(0, 1)", 1],
    ["and", "2017-01-02T00:00:00+00:00", "(0, 2)", 2],
    ["cheese", "2017-01-03T00:00:00+00:00", "(0, 3)", 3]
  ]
  @upsert_rows [
    ["biscuits", "2017-01-01T00:00:00+00:00", "(0, 1)", 1],
    ["gromit", "2017-01-04T00:00:00+00:00", "(0, 4)", 4]
  ]

  setup context do
    meta = context.meta

    {:ok, user} = UserActions.create("Trusted User", "password", "trusted@example.com") 
    {:ok, pk} = DataSetFieldActions.create(meta.id, "pk", "integer")
    DataSetFieldActions.create(meta.id, "datetime", "timestamptz")
    DataSetFieldActions.create(meta.id, "location", "text")
    DataSetFieldActions.create(meta.id, "data", "text")
    DataSetFieldActions.make_primary_key(pk)
    {:ok, constraint} = DataSetConstraintActions.create(meta.id, ["pk"])
    {:ok, job} = EtlJobActions.create(meta.id)
    VirtualPointFieldActions.create_from_loc(meta.id, "location")
    DataSetActions.create_data_set_table(meta)

    %{
      meta_id: meta.id,
      table_name: MetaActions.get_data_set_table_name(meta),
      constraint: constraint,
      job: job,
      user: user
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
      1, 2017-01-01T00:00:00,"(0, 1)",crackers
      2, 2017-02-02T00:00:00,"(0, 2)",and
      3, 2017-03-03T00:00:00,"(0, 3)",cheese
      """
    }
  end

  @doc """
  This helper function replaces the call to HTTPoison.get! made by a worker
  process. It returns a generic set of tsv data to ingest.

  ## Example

    iex> mock_tsv_data_request("http://doesnt_matter.com")
    %HTTPoison.Response{body: "tsv data..."}

  """
  def mock_tsv_data_request(_) do
    %HTTPoison.Response{
      body: """
      pk\tdatetime\tlocation\tdata
      1\t2017-01-01T00:00:00\t"(0, 1)"\tcrackers
      2\t2017-02-02T00:00:00\t"(0, 2)"\tand
      3\t2017-03-03T00:00:00\t"(0, 3)"\tcheese
      """
    }
  end

  @doc """
  This helper function replaces the call to HTTPoison.get! made by a worker
  process. It returns a generic set of csv data to upsert with. This method
  is meant to be used in conjunction with `mock_csv_data_request/1` to
  simulate making requests to changing datasets.

  ## Example

    iex> mock_csv_update_request("http://doesnt_matter.com")
    %HTTPoison.Response{body: "csv data..."}

  """
  def mock_csv_update_request(_) do
    %HTTPoison.Response{
      body: """
      pk, datetime, location, data
      1, 2017-01-01T00:00:00,"(0, 1)",biscuits
      4, 2017-04-04T00:00:00,"(0, 4)",gromit
      """
    }
  end

  @doc """
  This helper function replaces the call to HTTPoison.get! made by a worker
  process. It returns a generic set of json data to ingest.

  ## Example

    iex> mock_csv_data_request("http://doesnt_matter.com")
    %HTTPoison.Response{body: "json data..."}

  """
  def mock_json_data_request(_) do
    %HTTPoison.Response{
      body: """
      [{
        "pk": 1,
        "datetime": "2017-01-01T00:00:00",
        "location": "(0, 1)",
        "data": "crackers"
      },{
        "pk": 2,
        "datetime": "2017-01-02T00:00:00",
        "location": "(0, 2)",
        "data": "and"
      },{
        "pk": 3,
        "datetime": "2017-01-03T00:00:00",
        "location": "(0, 3)",
        "data": "cheese"
      }]
      """
    }
  end

  @doc """
  This helper function replaces the call to HTTPoison.get! made by a worker
  process. It returns a generic set of json data for updates.

  ## Example

    iex> mock_csv_data_request("http://doesnt_matter.com")
    %HTTPoison.Response{body: "json data..."}

  """
  def mock_json_update_request(_) do
    %HTTPoison.Response{
      body: """
      [{
        "pk": 1,
        "datetime": "2017-01-01T00:00:00",
        "location": "(0, 1)",
        "data": "biscuits"
      },{
        "pk": 4,
        "datetime": "2017-01-04T00:00:00",
        "location": "(0, 4)",
        "data": "gromit"
      }]
      """
    }
  end

  @doc """
  This helper function replaces the call to HTTPoison.get! made by a worker
  process. It returns a generic set of shape data for updates.

  ## Example

    iex> mock_shapefile_data_request("http://doesnt_matter.com")
    %HTTPoison.Response{body: "shapefile data..."}

  """
  def mock_shapefile_data_request(_) do
    %HTTPoison.Response{
      body: File.read!("test/plenario2_etl/fixtures/watersheds.zip")
    }
  end

  test :download! do
    with_mock HTTPoison, get!: &mock_csv_data_request/1 do
      name = "chicago_tree_trimming"
      source = "https://example.com/dataset.csv"
      path = Worker.download!(name, source, "csv")

      assert path === "/tmp/#{name}.csv"
      assert File.exists?("/tmp/#{name}.csv")
    end
  end

  test :upsert!, %{meta: meta} do
    Worker.upsert!(meta, @insert_rows)
    %Postgrex.Result{rows: rows} = query!(Plenario2.Repo, @select_query, [])

    assert [
             [1, {{2017, 1, 1}, {_, 0, 0, 0}}, "(0, 1)", "crackers"],
             [2, {{2017, 1, 2}, {_, 0, 0, 0}}, "(0, 2)", "and"],
             [3, {{2017, 1, 3}, {_, 0, 0, 0}}, "(0, 3)", "cheese"]
           ] = Enum.sort(rows)
  end

  test :"upsert!/2 updates", %{meta: meta} do
    Worker.upsert!(meta, @insert_rows)
    Worker.upsert!(meta, @upsert_rows)
    %Postgrex.Result{rows: rows} = query!(Plenario2.Repo, @select_query, [])

    assert [
             [1, {{2017, 1, 1}, {_, 0, 0, 0}}, "(0, 1)", "biscuits"],
             [2, {{2017, 1, 2}, {_, 0, 0, 0}}, "(0, 2)", "and"],
             [3, {{2017, 1, 3}, {_, 0, 0, 0}}, "(0, 3)", "cheese"],
             [4, {{2017, 1, 4}, {_, 0, 0, 0}}, "(0, 4)", "gromit"]
           ] = Enum.sort(rows)
  end

  test :contains!, %{meta: meta} do
    Worker.upsert!(meta, @insert_rows)
    rows = Worker.contains!(meta, @upsert_rows)
    assert [["crackers", {{2017, 1, 1}, {_, 0, 0, 0}}, "(0, 1)", 1]] = rows
  end

  test :create_diffs, %{meta: meta, job: job} do
    row1 = ["original", "original", "original"]
    row2 = ["original", "changed", "changed"]
    Worker.create_diffs(meta, job, row1, row2)
    diffs = Repo.all(DataSetDiff)
    assert Enum.count(diffs) === 2
  end

  test :load_chunk, %{meta: meta, job: job} do
    Worker.load_chunk!(self(), meta, job, Enum.map([
      %{
        "data" => "crackers",
        "datetime" => "2017-01-01T00:00:00",
        "location" => "(0, 1)",
        "pk" => 1
      },
      %{
        "data" => "and",
        "datetime" => "2017-01-02T00:00:00",
        "location" => "(0, 2)",
        "pk" => 2
      },
      %{
        "data" => "cheese",
        "datetime" => "2017-01-03T00:00:00",
        "location" => "(0, 3)",
        "pk" => 3
      }
    ], &Enum.to_list/1))

    %Postgrex.Result{rows: rows} = query!(Plenario2.Repo, @select_query, [])

    assert [
             [1, {{2017, 1, 1}, {_, 0, 0, 0}}, "(0, 1)", "crackers"],
             [2, {{2017, 1, 2}, {_, 0, 0, 0}}, "(0, 2)", "and"],
             [3, {{2017, 1, 3}, {_, 0, 0, 0}}, "(0, 3)", "cheese"]
           ] = Enum.sort(rows)
  end

  test :load!, %{meta: meta} do
    with_mock HTTPoison, get!: &mock_csv_data_request/1 do
      Worker.load(%{meta_id: meta.id})
      %Postgrex.Result{rows: rows} = query!(Plenario2.Repo, @select_query, [])

      assert [
               [1, {{2017, 1, 1}, {_, 0, 0, 0}}, "(0, 1)", "crackers"],
               [2, {{2017, 2, 2}, {_, 0, 0, 0}}, "(0, 2)", "and"],
               [3, {{2017, 3, 3}, {_, 0, 0, 0}}, "(0, 3)", "cheese"]
             ] = Enum.sort(rows)
    end
  end

  test "load/1 loads tsv", %{meta: meta} do
    MetaActions.update_source_info(meta, source_type: "tsv")
    with_mock HTTPoison, get!: &mock_tsv_data_request/1 do
      Worker.load(%{meta_id: meta.id})
      %Postgrex.Result{rows: rows} = query!(Plenario2.Repo, @select_query, [])

      assert [
               [1, {{2017, 1, 1}, {_, 0, 0, 0}}, "(0, 1)", "crackers"],
               [2, {{2017, 2, 2}, {_, 0, 0, 0}}, "(0, 2)", "and"],
               [3, {{2017, 3, 3}, {_, 0, 0, 0}}, "(0, 3)", "cheese"]
             ] = Enum.sort(rows)
    end
  end

  test "load/1 generates diffs upon upsert", %{meta: meta} do
    with_mock HTTPoison, get!: &mock_csv_data_request/1 do
      Worker.load(%{meta_id: meta.id})
    end

    with_mock HTTPoison, get!: &mock_csv_update_request/1 do
      Worker.load(%{meta_id: meta.id})
      %Postgrex.Result{rows: rows} = query!(Plenario2.Repo, @select_query, [])
      diffs = Repo.all(DataSetDiff)

      assert [
               [1, {{2017, 1, 1}, {_, 0, 0, 0}}, "(0, 1)", "biscuits"],
               [2, {{2017, 2, 2}, {_, 0, 0, 0}}, "(0, 2)", "and"],
               [3, {{2017, 3, 3}, {_, 0, 0, 0}}, "(0, 3)", "cheese"],
               [4, {{2017, 4, 4}, {_, 0, 0, 0}}, "(0, 4)", "gromit"]
             ] = Enum.sort(rows)

      assert Enum.count(diffs) === 1
    end
  end

  test "load/1 ingests json dataset", %{meta: meta} do
    MetaActions.update_source_info(meta, source_type: "json")

    with_mock HTTPoison, get!: &mock_json_data_request/1 do
      Worker.load(%{meta_id: meta.id})
    end

    %Postgrex.Result{rows: rows} = query!(Plenario2.Repo, @select_query, [])

    assert [
             [1, {{2017, 1, 1}, {_, 0, 0, 0}}, "(0, 1)", "crackers"],
             [2, {{2017, 1, 2}, {_, 0, 0, 0}}, "(0, 2)", "and"],
             [3, {{2017, 1, 3}, {_, 0, 0, 0}}, "(0, 3)", "cheese"]
           ] = Enum.sort(rows)
  end

  test "load/1 ingests json dataset and creates diffs", %{meta: meta} do
    MetaActions.update_source_info(meta, source_type: "json")

    with_mock HTTPoison, get!: &mock_json_data_request/1 do
      Worker.load(%{meta_id: meta.id})
    end

    with_mock HTTPoison, get!: &mock_json_update_request/1 do
      Worker.load(%{meta_id: meta.id})
      %Postgrex.Result{rows: rows} = query!(Plenario2.Repo, @select_query, [])
      diffs = Repo.all(DataSetDiff)

      assert [
               [1, {{2017, 1, 1}, {_, 0, 0, 0}}, "(0, 1)", "biscuits"],
               [2, {{2017, 1, 2}, {_, 0, 0, 0}}, "(0, 2)", "and"],
               [3, {{2017, 1, 3}, {_, 0, 0, 0}}, "(0, 3)", "cheese"],
               [4, {{2017, 1, 4}, {_, 0, 0, 0}}, "(0, 4)", "gromit"]
             ] = Enum.sort(rows)

      assert Enum.count(diffs) === 1
    end
  end
end
