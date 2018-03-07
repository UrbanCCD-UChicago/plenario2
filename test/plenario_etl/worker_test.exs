defmodule PlenarioEtl.Testing.WorkerTest do
  use ExUnit.Case

  import Mock

  alias Plenario.ModelRegistry

  alias Plenario.Actions.{
    UserActions,
    MetaActions,
    DataSetFieldActions,
    VirtualPointFieldActions,
    UniqueConstraintActions,
    DataSetActions
  }

  alias PlenarioEtl.Actions.EtlJobActions

  @json_fixture_path "test/fixtures/aot-chicago.json"

  @corrupt_json_fixture_path "test/fixtures/aot-chicago-corrupted.json"

  @csv_fixutre_path "test/fixtures/beach-lab-dna.csv"

  @corrupted_csv_fixutre_path "test/fixtures/beach-lab-dna-corrupted.csv"

  setup do
    # checkout a connection
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Plenario.Repo)

    # clear the registry
    ModelRegistry.clear()

    # setup a user
    {:ok, user} = UserActions.create("name", "email@example.com", "password")

    # setup a metas with fields, etc.
    {:ok, csv_meta} = MetaActions.create("Chicago Beach Lab DNA Tests", user, "https://example.com/csv", "csv")
    {:ok, id} = DataSetFieldActions.create(csv_meta, "DNA Test ID", "text")
    {:ok, _} = DataSetFieldActions.create(csv_meta, "DNA Reading Mean", "float")
    {:ok, _} = DataSetFieldActions.create(csv_meta, "DNA Sample 1 Reading", "float")
    {:ok, _} = DataSetFieldActions.create(csv_meta, "DNA Sample 2 Reading", "float")
    {:ok, _} = DataSetFieldActions.create(csv_meta, "DNA Sample Timestamp", "timestamptz")
    {:ok, loc} = DataSetFieldActions.create(csv_meta, "Location", "text")
    {:ok, _} = VirtualPointFieldActions.create(csv_meta, loc.id)
    {:ok, _} = UniqueConstraintActions.create(csv_meta, [id.id])

    {:ok, json_meta} = MetaActions.create("Array of Things Chicago", user, "https://example.com/json", "json")
    {:ok, id} = DataSetFieldActions.create(json_meta, "node_id", "text")
    {:ok, lat} = DataSetFieldActions.create(json_meta, "latitude", "float")
    {:ok, lon} = DataSetFieldActions.create(json_meta, "longitude", "float")
    {:ok, _} = DataSetFieldActions.create(json_meta, "timestamp", "timestamptz")
    {:ok, _} = DataSetFieldActions.create(json_meta, "observations", "jsonb")
    {:ok, _} = DataSetFieldActions.create(json_meta, "human_address", "text")
    {:ok, _} = VirtualPointFieldActions.create(json_meta, lat.id, lon.id)
    {:ok, _} = UniqueConstraintActions.create(json_meta, [id.id])

    # bring up the data set tables
    :ok = DataSetActions.up!(csv_meta)
    :ok = DataSetActions.up!(json_meta)

    # return context
    {:ok, [csv_meta: csv_meta, json_meta: json_meta]}
  end

  defp mock_options_response(_) do
    {:ok, %HTTPoison.Response{status_code: 200}}
  end

  defp mock_csv_response(path) do
    body =
      File.stream!(path)
      |> CSV.decode(headers: true)

    %HTTPoison.Response{body: body}
  end

  defp mock_json_response(path) do
    body =
      File.read!(path)
      |> Poison.decode!()

    %HTTPoison.Response{body: body}
  end

  test "ingest csv", %{csv_meta: meta} do
    with_mock HTTPoison, options: &mock_options_response/1 do
      # set meta's source url so we get the right fixture
      {:ok, meta} = MetaActions.update(meta, source_url: @csv_fixutre_path)
    end

    with_mock HTTPoison, get!: &mock_csv_response/1 do
      # ingest the data set
      {job, task} = PlenarioEtl.ingest(meta)
    end
  end

  test "ingest json", %{json_meta: meta} do
    with_mock HTTPoison, options: &mock_options_response/1 do
      # set meta's source url so we get the right fixture
      {:ok, meta} = MetaActions.update(meta, source_url: @json_fixture_path)
    end

    with_mock HTTPoison, get!: &mock_csv_response/1 do
      # ingest the data set
      {job, task} = PlenarioEtl.ingest(meta)
    end
  end

  test "ingest csv partial success", %{csv_meta: meta} do
    with_mock HTTPoison, options: &mock_options_response/1 do
      # set meta's source url so we get the right fixture
      {:ok, meta} = MetaActions.update(meta, source_url: @corrupted_csv_fixutre_path)
    end

    with_mock HTTPoison, get!: &mock_csv_response/1 do
      # ingest the data set
      {job, task} = PlenarioEtl.ingest(meta)
    end
  end

  test "ingest json partial success", %{json_meta: meta} do
    with_mock HTTPoison, options: &mock_options_response/1 do
      # set meta's source url so we get the right fixture
      {:ok, meta} = MetaActions.update(meta, source_url: @corrupt_json_fixture_path)
    end

    with_mock HTTPoison, get!: &mock_csv_response/1 do
      # ingest the data set
      {job, task} = PlenarioEtl.ingest(meta)
    end
  end
end



# defmodule PlenarioEtl.Testing.OldWorkerTest do
#   use Plenario.Testing.DataCase
#   doctest PlenarioEtl.Worker
#
#   alias Plenario.Actions.{
#     DataSetActions,
#     UniqueConstraintActions,
#     DataSetFieldActions,
#     MetaActions,
#     VirtualPointFieldActions,
#     UserActions
#   }
#
#   alias Plenario.{ModelRegistry, Repo}
#   alias PlenarioEtl.Actions.EtlJobActions
#   alias PlenarioEtl.Schemas.DataSetDiff
#   alias PlenarioEtl.Worker
#
#   import Ecto.Adapters.SQL, only: [query!: 3]
#   import Mock
#
#   require HTTPoison
#
#   @fixture_columns ["pk", "datetime", "location", "data"]
#
#   @insert_rows [
#     %{
#       "data" => "crackers",
#       "datetime" => "2017-01-01T00:00:00+00:00",
#       "location" => "(0, 1)",
#       "pk" => 1
#     },
#     %{
#       "data" => "and",
#       "datetime" => "2017-01-02T00:00:00+00:00",
#       "location" => "(0, 2)",
#       "pk" => 2
#     },
#     %{
#       "data" => "cheese",
#       "datetime" => "2017-01-03T00:00:00+00:00",
#       "location" => "(0, 3)",
#       "pk" => 3
#     }
#   ]
#
#   @upsert_rows [
#     %{
#       "data" => "biscuits",
#       "datetime" => "2017-01-01T00:00:00+00:00",
#       "location" => "(0, 1)",
#       "pk" => 1
#     },
#     %{
#       "data" => "gromit",
#       "datetime" => "2017-01-04T00:00:00+00:00",
#       "location" => "(0, 4)",
#       "pk" => 4
#     }
#   ]
#
#   @csv_fixture_path "test/fixtures/clinics.csv"
#   @csv_updated_fixture_path "test/fixtures/clinics_updated.csv"
#   @csv_error_fixture_path "test/fixtures/clinics_error.csv"
#   @json_fixture_path "test/fixtures/clinics.json"
#   @shp_fixture_path "test/fixtures/Watersheds.zip"
#   @tsv_fixture_path "test/fixtures/clinics.tsv"
#
#   setup context do
#     Plenario.ModelRegistry.clear()
#
#     meta = context.meta
#     {:ok, user} = UserActions.create("Trusted User", "trusted@example.com", "password")
#     {:ok, pk_field} = DataSetFieldActions.create(meta.id, "pk", "integer")
#     {:ok, dt_field} = DataSetFieldActions.create(meta.id, "datetime", "timestamptz")
#     {:ok, loc_field} = DataSetFieldActions.create(meta.id, "location", "text")
#     {:ok, data_field} = DataSetFieldActions.create(meta.id, "data", "text")
#     {:ok, constraint} = UniqueConstraintActions.create(meta.id, [pk_field.id, loc_field.id])
#     {:ok, job} = EtlJobActions.create(meta.id)
#     VirtualPointFieldActions.create(meta.id, loc_field: loc_field)
#     DataSetActions.up!(meta)
#
#     %{
#       meta_id: meta.id,
#       table_name: meta.table_name,
#       constraint: constraint,
#       job: job,
#       job_id: job.id,
#       user: user
#     }
#   end
#
#   @doc """
#   This helper function replaces the call to HTTPoison.get! made by a worker
#   process. It returns a generic set of csv data to ingest.
#
#   ## Example
#
#     iex> mock_csv_data_request("http://doesnt_matter.com")
#     %HTTPoison.Response{body: "csv data..."}
#
#   """
#   def mock_csv_data_request(_) do
#     %HTTPoison.Response{
#       body: """
#       pk,datetime,location,data
#       1,2017-01-01T00:00:00,"(0, 1)",crackers
#       2,2017-02-02T00:00:00,"(0, 2)",and
#       3,2017-03-03T00:00:00,"(0, 3)",cheese
#       """
#     }
#   end
#
#   @doc """
#   This helper function replaces the call to HTTPoison.get! made by a worker
#   process. It returns a generic set of tsv data to ingest.
#
#   ## Example
#
#     iex> mock_tsv_data_request("http://doesnt_matter.com")
#     %HTTPoison.Response{body: "tsv data..."}
#
#   """
#   def mock_tsv_data_request(_) do
#     %HTTPoison.Response{
#       body: """
#       pk\tdatetime\tlocation\tdata
#       1\t2017-01-01T00:00:00\t"(0, 1)"\tcrackers
#       2\t2017-02-02T00:00:00\t"(0, 2)"\tand
#       3\t2017-03-03T00:00:00\t"(0, 3)"\tcheese
#       """
#     }
#   end
#
#   @doc """
#   This helper function replaces the call to HTTPoison.get! made by a worker
#   process. It returns a generic set of csv data to upsert with. This method
#   is meant to be used in conjunction with `mock_csv_data_request/1` to
#   simulate making requests to changing datasets.
#
#   ## Example
#
#     iex> mock_csv_update_request("http://doesnt_matter.com")
#     %HTTPoison.Response{body: "csv data..."}
#
#   """
#   def mock_csv_update_request(_) do
#     %HTTPoison.Response{
#       body: """
#       pk,datetime,location,data
#       1,2017-01-01T00:00:00,"(0, 1)",biscuits
#       4,2017-04-04T00:00:00,"(0, 4)",gromit
#       """
#     }
#   end
#
#   @doc """
#   This helper function replaces the call to HTTPoison.get! made by a worker
#   process. It returns a generic set of json data to ingest.
#
#   ## Example
#
#     iex> mock_csv_data_request("http://doesnt_matter.com")
#     %HTTPoison.Response{body: "json data..."}
#
#   """
#   def mock_json_data_request(_) do
#     %HTTPoison.Response{
#       body: """
#       [{
#         "pk": 1,
#         "datetime": "2017-01-01T00:00:00",
#         "location": "(0, 1)",
#         "data": "crackers"
#       },{
#         "pk": 2,
#         "datetime": "2017-01-02T00:00:00",
#         "location": "(0, 2)",
#         "data": "and"
#       },{
#         "pk": 3,
#         "datetime": "2017-01-03T00:00:00",
#         "location": "(0, 3)",
#         "data": "cheese"
#       }]
#       """
#     }
#   end
#
#   @doc """
#   This helper function replaces the call to HTTPoison.get! made by a worker
#   process. It returns a generic set of json data for updates.
#
#   ## Example
#
#     iex> mock_csv_data_request("http://doesnt_matter.com")
#     %HTTPoison.Response{body: "json data..."}
#
#   """
#   def mock_json_update_request(_) do
#     %HTTPoison.Response{
#       body: """
#       [{
#         "pk": 1,
#         "datetime": "2017-01-01T00:00:00",
#         "location": "(0, 1)",
#         "data": "biscuits"
#       },{
#         "pk": 4,
#         "datetime": "2017-01-04T00:00:00",
#         "location": "(0, 4)",
#         "data": "gromit"
#       }]
#       """
#     }
#   end
#
#   @doc """
#   This helper function replaces the call to HTTPoison.get! made by a worker
#   process. It returns a generic set of shape data for updates.
#
#   ## Example
#
#     iex> mock_shapefile_data_request("http://doesnt_matter.com")
#     %HTTPoison.Response{body: "shapefile data..."}
#
#   """
#   def mock_shapefile_data_request(_) do
#     %HTTPoison.Response{
#       body: File.read!("test/plenario_etl/fixtures/watersheds.zip")
#     }
#   end
#
#   test :download! do
#     with_mock HTTPoison, get!: &mock_csv_data_request/1 do
#       name = "chicago_tree_trimming"
#       source = "https://example.com/dataset.csv"
#       path = Worker.download!(name, source, "csv")
#
#       assert path === "/tmp/#{name}.csv"
#       assert File.exists?("/tmp/#{name}.csv")
#     end
#   end
#
#   @tag :upsert!
#   test "upsert!/2 inserts rows", %{meta: meta, constraint: constraint} do
#     constraints = UniqueConstraintActions.get_field_names(constraint)
#     Worker.upsert!(meta, @insert_rows, constraints)
#     model = Plenario.ModelRegistry.lookup(meta.slug)
#     rows = Repo.all(model)
#
#     assert length(rows) == 3
#   end
#
#   @tag :upsert!
#   test "upsert!/2 updates and inserts rows", %{meta: meta, constraint: constraint} do
#     constraints = UniqueConstraintActions.get_field_names(constraint)
#     Worker.upsert!(meta, @insert_rows, constraints)
#     Worker.upsert!(meta, @upsert_rows, constraints)
#     model = Plenario.ModelRegistry.lookup(meta.slug)
#     rows = Repo.all(model)
#     changed_row = Enum.find(rows, fn row -> Map.get(row, :pk) == 1 end)
#
#     assert length(rows) == 4
#     assert Map.get(changed_row, :data) == "biscuits"
#   end
#
#   @tag :contains!
#   test "contains!/3", %{meta: meta, constraint: constraint} do
#     constraints =
#       UniqueConstraintActions.get_field_names(constraint)
#       |> Enum.map(&String.to_atom/1)
#
#     Worker.upsert!(meta, @insert_rows, constraints)
#     [row | _] = Worker.contains!(meta, @upsert_rows, constraints)
#
#     assert Map.get(row, :pk) == 1
#   end
#
#   @tag :create_diffs
#   test :create_diffs, %{meta: meta, job: job} do
#     row1 = %{colA: "original", colB: "original", colC: "original"}
#     row2 = %{colA: "original", colB: "changed", colC: "changed"}
#     Worker.create_diffs(meta, job, row1, row2)
#     diffs = Repo.all(DataSetDiff)
#     assert Enum.count(diffs) === 2
#   end
#
#   @tag :load_chunk
#   test :load_chunk, %{meta: meta, job: job, constraint: constraint} do
#     constraints =
#       UniqueConstraintActions.get_field_names(constraint)
#       |> Enum.map(&String.to_atom/1)
#
#     Worker.load_chunk!(meta, job, @insert_rows, constraints)
#
#     %Postgrex.Result{rows: rows} =
#       query!(
#         Plenario.Repo,
#         """
#         SELECT "#{Enum.join(@fixture_columns, "\", \"")}" from "#{meta.table_name}";
#         """,
#         []
#       )
#
#     assert [
#              [1, {{2017, 1, 1}, {_, 0, 0, 0}}, "(0, 1)", "crackers"],
#              [2, {{2017, 1, 2}, {_, 0, 0, 0}}, "(0, 2)", "and"],
#              [3, {{2017, 1, 3}, {_, 0, 0, 0}}, "(0, 3)", "cheese"]
#            ] = Enum.sort(rows)
#   end
#
#   test :load!, %{meta: meta, job: job} do
#     with_mock HTTPoison, get!: &mock_csv_data_request/1 do
#       Worker.load(%{meta_id: meta.id, job_id: job.id})
#       %Postgrex.Result{rows: rows} =
#         query!(
#           Plenario.Repo,
#           """
#           SELECT "#{Enum.join(@fixture_columns, "\", \"")}" from "#{meta.table_name}";
#           """,
#           []
#         )
#
#       assert [
#                [1, {{2017, 1, 1}, {_, 0, 0, 0}}, "(0, 1)", "crackers"],
#                [2, {{2017, 2, 2}, {_, 0, 0, 0}}, "(0, 2)", "and"],
#                [3, {{2017, 3, 3}, {_, 0, 0, 0}}, "(0, 3)", "cheese"]
#              ] = Enum.sort(rows)
#     end
#   end
#
#   test "load/1 generates diffs upon upsert", %{meta: meta, job: job} do
#     with_mock HTTPoison, get!: &mock_csv_data_request/1 do
#       Worker.load(%{meta_id: meta.id, job_id: job.id})
#     end
#
#     with_mock HTTPoison, get!: &mock_csv_update_request/1 do
#       Worker.load(%{meta_id: meta.id, job_id: job.id})
#       %Postgrex.Result{rows: rows} =
#         query!(
#           Plenario.Repo,
#           """
#           SELECT "#{Enum.join(@fixture_columns, "\", \"")}" from "#{meta.table_name}";
#           """,
#           []
#         )
#       diffs = Repo.all(DataSetDiff)
#
#       assert [
#                [1, {{2017, 1, 1}, {_, 0, 0, 0}}, "(0, 1)", "biscuits"],
#                [2, {{2017, 2, 2}, {_, 0, 0, 0}}, "(0, 2)", "and"],
#                [3, {{2017, 3, 3}, {_, 0, 0, 0}}, "(0, 3)", "cheese"],
#                [4, {{2017, 4, 4}, {_, 0, 0, 0}}, "(0, 4)", "gromit"]
#              ] = Enum.sort(rows)
#
#       # Bug(heyzoos) It creates an extra diff for datetimes of differing
#       # precisions. Need to fix this.
#       # assert Enum.count(diffs) === 1
#       assert Enum.count(diffs) === 2
#     end
#   end
#
#   test "load/1 ingests json dataset", %{meta: meta, job: job} do
#     MetaActions.update(meta, source_type: "json")
#
#     with_mock HTTPoison, get!: &mock_json_data_request/1 do
#       Worker.load(%{meta_id: meta.id, job_id: job.id})
#     end
#
#     %Postgrex.Result{rows: rows} =
#       query!(
#         Plenario.Repo,
#         """
#         SELECT "#{Enum.join(@fixture_columns, "\", \"")}" from "#{meta.table_name}";
#         """,
#         []
#       )
#
#     assert [
#              [1, {{2017, 1, 1}, {_, 0, 0, 0}}, "(0, 1)", "crackers"],
#              [2, {{2017, 1, 2}, {_, 0, 0, 0}}, "(0, 2)", "and"],
#              [3, {{2017, 1, 3}, {_, 0, 0, 0}}, "(0, 3)", "cheese"]
#            ] = Enum.sort(rows)
#   end
#
#   test "load/1 ingests json dataset and creates diffs", %{meta: meta, job: job} do
#     MetaActions.update(meta, source_type: "json")
#
#     with_mock HTTPoison, get!: &mock_json_data_request/1 do
#       Worker.load(%{meta_id: meta.id, job_id: job.id})
#     end
#
#     with_mock HTTPoison, get!: &mock_json_update_request/1 do
#       Worker.load(%{meta_id: meta.id, job_id: job.id})
#       %Postgrex.Result{rows: rows} =
#         query!(
#           Plenario.Repo,
#           """
#           SELECT "#{Enum.join(@fixture_columns, "\", \"")}" from "#{meta.table_name}";
#           """,
#           []
#         )
#       diffs = Repo.all(DataSetDiff)
#
#       assert [
#                [1, {{2017, 1, 1}, {_, 0, 0, 0}}, "(0, 1)", "biscuits"],
#                [2, {{2017, 1, 2}, {_, 0, 0, 0}}, "(0, 2)", "and"],
#                [3, {{2017, 1, 3}, {_, 0, 0, 0}}, "(0, 3)", "cheese"],
#                [4, {{2017, 1, 4}, {_, 0, 0, 0}}, "(0, 4)", "gromit"]
#              ] = Enum.sort(rows)
#
#       # Bug(heyzoos) It creates an extra diff for datetimes of differing
#       # precisions. Need to fix this.
#       # assert Enum.count(diffs) === 1
#       assert Enum.count(diffs) === 2
#     end
#   end
#
#   @doc """
#   This helper function replaces the call to HTTPoison.get! made by a worker
#   process. It returns data loaded from a file as the response body.
#   """
#   def load_mock(path) do
#     fn _ -> %HTTPoison.Response{body: File.read!(path)} end
#   end
#
#   describe "integration tests" do
#     setup do
#       {:ok, user} = UserActions.create("Trusted User", "user@example.com", "password")
#       {:ok, meta} = MetaActions.create("clinics", user.id, "https://www.example.com/chicago-tree-trimmings", "csv")
#
#       {:ok, _} = DataSetFieldActions.create(meta.id, "Date", "text")
#       {:ok, _} = DataSetFieldActions.create(meta.id, "Start Time", "text")
#       {:ok, _} = DataSetFieldActions.create(meta.id, "End Time", "text")
#       {:ok, _} = DataSetFieldActions.create(meta.id, "Day", "text")
#       {:ok, _} = DataSetFieldActions.create(meta.id, "Event", "text")
#       {:ok, _} = DataSetFieldActions.create(meta.id, "Event Type", "text")
#       {:ok, _} = DataSetFieldActions.create(meta.id, "Address", "text")
#       {:ok, _} = DataSetFieldActions.create(meta.id, "City", "text")
#       {:ok, _} = DataSetFieldActions.create(meta.id, "State", "text")
#       {:ok, _} = DataSetFieldActions.create(meta.id, "Zip", "integer")
#       {:ok, _} = DataSetFieldActions.create(meta.id, "Phone", "text")
#       {:ok, _} = DataSetFieldActions.create(meta.id, "Community Area Number", "integer")
#       {:ok, _} = DataSetFieldActions.create(meta.id, "Community Area Name", "text")
#       {:ok, _} = DataSetFieldActions.create(meta.id, "Ward", "integer")
#       {:ok, _} = DataSetFieldActions.create(meta.id, "Latitude", "float")
#       {:ok, _} = DataSetFieldActions.create(meta.id, "Longitude", "float")
#       {:ok, f} = DataSetFieldActions.create(meta.id, "Location", "text")
#
#       UniqueConstraintActions.create(meta.id, [f.id])
#       job = EtlJobActions.create!(meta.id)
#       DataSetActions.up!(meta)
#       VirtualPointFieldActions.create(meta.id, loc_field: f)
#
#       %{fixture_meta: meta, job: job}
#     end
#
#     test "load/1 loads csv fixture", %{fixture_meta: meta, job: job} do
#       MetaActions.update(meta, source_type: "csv")
#       get! = load_mock(@csv_fixture_path)
#
#       with_mock HTTPoison, get!: fn url -> get!.(url) end do
#         Worker.load(%{meta_id: meta.id, job_id: job.id})
#         clinics = ModelRegistry.lookup(meta.slug) |> Repo.all()
#         assert 65 == Enum.count(clinics)
#       end
#     end
#
#     test "load/1 loads csv fixture with subset of columns" do
#       {:ok, user} = UserActions.create("subset_user", "subset@email.com", "password")
#       {:ok, meta} = MetaActions.create("clinics_subset", user.id, "https://example.com/subset", "csv")
#       {:ok, job} = EtlJobActions.create(meta.id)
#
#       DataSetFieldActions.create(meta.id, "Community Area Name", "text")
#       DataSetFieldActions.create(meta.id, "Ward", "integer")
#       DataSetFieldActions.create(meta.id, "Latitude", "float")
#       DataSetFieldActions.create(meta.id, "Longitude", "float")
#       {:ok, f} = DataSetFieldActions.create(meta.id, "Location", "text")
#
#       UniqueConstraintActions.create(meta.id, [f.id])
#       MetaActions.update(meta, source_type: "csv")
#       DataSetActions.up!(meta)
#       VirtualPointFieldActions.create(meta.id, loc_field: f)
#
#       get! = load_mock(@csv_fixture_path)
#       with_mock HTTPoison, get!: fn url -> get!.(url) end do
#         Worker.load(%{meta_id: meta.id, job_id: job.id})
#         clinics = ModelRegistry.lookup(meta.slug)
#         rows = Repo.all(clinics)
#         columns =
#           List.first(rows)
#           |> Map.keys()
#           |> Enum.map(&to_string/1)
#           |> Enum.filter(fn row -> !String.starts_with?(row, "__") end)
#
#         assert 65 == Enum.count(rows)
#         assert ["Community Area Name", "Latitude", "Location", "Longitude", "Ward"] == columns
#       end
#     end
#
#     test "load/1 loads updated csv fixture", %{fixture_meta: meta, job: job} do
#       MetaActions.update(meta, source_type: "csv")
#
#       get! = load_mock(@csv_fixture_path)
#
#       with_mock HTTPoison, get!: fn url -> get!.(url) end do
#         Worker.load(%{meta_id: meta.id, job_id: job.id})
#         clinics = ModelRegistry.lookup(meta.slug)
#         rows = Repo.all(clinics)
#         assert 65 == Enum.count(rows)
#       end
#
#       get! = load_mock(@csv_updated_fixture_path)
#
#       with_mock HTTPoison, get!: fn url -> get!.(url) end do
#         Worker.load(%{meta_id: meta.id, job_id: job.id})
#         rows = Repo.all(DataSetDiff)
#         assert 1 == Enum.count(rows)
#       end
#     end
#
#     test "load/1 loads tsv fixture", %{fixture_meta: meta, job: job} do
#       MetaActions.update(meta, source_type: "tsv")
#       get! = load_mock(@tsv_fixture_path)
#
#       with_mock HTTPoison, get!: fn url -> get!.(url) end do
#         Worker.load(%{meta_id: meta.id, job_id: job.id})
#         rows = ModelRegistry.lookup(meta.slug) |> Repo.all()
#         assert 65 == Enum.count(rows)
#       end
#     end
#
#     test "load/1 loads json fixture", %{fixture_meta: meta, job: job} do
#       MetaActions.update(meta, source_type: "json")
#       get! = load_mock(@json_fixture_path)
#
#       with_mock HTTPoison, get!: fn url -> get!.(url) end do
#         Worker.load(%{meta_id: meta.id, job_id: job.id})
#         rows = ModelRegistry.lookup(meta.slug) |> Repo.all()
#         assert 65 == Enum.count(rows)
#       end
#     end
#
#     test "load/1 loads embedded json fixture", %{job: job} do
#       {:ok, user} = UserActions.create("name", "email@example.com", "password")
#       {:ok, meta} = MetaActions.create("AoT", user, "https://example.com/1", "json")
#       {:ok, node_id} = DataSetFieldActions.create(meta, "node_id", "text")
#       {:ok, lat} = DataSetFieldActions.create(meta, "latitude", "float")
#       {:ok, lon} = DataSetFieldActions.create(meta, "longitude", "float")
#       {:ok, _} = DataSetFieldActions.create(meta, "timestamp", "timestamptz")
#       {:ok, _} = DataSetFieldActions.create(meta, "tags", "jsonb")
#       {:ok, _} = DataSetFieldActions.create(meta, "observations", "jsonb")
#       {:ok, _} = UniqueConstraintActions.create(meta, [node_id.id])
#       {:ok, _} = VirtualPointFieldActions.create(meta, lat.id, lon.id)
#
#       m = MetaActions.get(meta.id)
#       {:ok, _} = MetaActions.submit_for_approval(m)
#       m = MetaActions.get(meta.id)
#       {:ok, _} = MetaActions.approve(m)
#
#       get! = load_mock("test/fixtures/embedded.json")
#
#       with_mock HTTPoison, get!: fn url -> get!.(url) end do
#         Worker.load(%{meta_id: meta.id, job_id: job.id})
#         rows = ModelRegistry.lookup(meta.slug) |> Repo.all()
#         assert 3 == Enum.count(rows)
#       end
#     end
#
#     test "load/1 loads shp fixture" do
#       {:ok, user} = UserActions.create("Trusted User", "shapeuser@example.com", "password")
#       {:ok, meta} = MetaActions.create("watersheds", user.id, "example.com/watersheds", "shp")
#       {:ok, job} = EtlJobActions.create(meta)
#
#       MetaActions.update(meta, source_type: "shp")
#       get! = load_mock(@shp_fixture_path)
#
#       with_mock HTTPoison, get!: fn url -> get!.(url) end do
#         Worker.load(%{meta_id: meta.id, job_id: job.id})
#         %Postgrex.Result{rows: rows} = query!(Plenario.Repo, "select * from watersheds", [])
#         assert 7 == Enum.count(rows)
#       end
#     end
#
#     test "async_load/1 loads csv fixture and completes job state", %{fixture_meta: meta} do
#       MetaActions.update(meta, source_type: "csv")
#
#       get! = load_mock(@csv_fixture_path)
#       with_mock HTTPoison, get!: fn url -> get!.(url) end do
#         %{task: task, job: job, meta: meta} = Worker.async_load!(meta.id)
#         Task.await(task)
#
#         query = "select * from etl_jobs where id = #{job.id}"
#         %Postgrex.Result{rows: rows} = query!(Plenario.Repo, query, [])
#         [row | _] = rows
#
#         job_id = job.id()
#         meta_id = meta.id()
#         assert [^job_id, "completed", _, _, nil, ^meta_id, _, _] = row
#       end
#     end
#
#     test "async_load/1 loads csv fixture and errs job state", %{fixture_meta: meta} do
#       MetaActions.update(meta, source_type: "csv")
#
#       get! = load_mock(@csv_error_fixture_path)
#       with_mock HTTPoison, get!: fn url -> get!.(url) end do
#         %{task: task, job: job, meta: meta} = Worker.async_load!(meta.id)
#         Task.await(task)
#
#         query = "select * from etl_jobs where id = #{job.id}"
#         %Postgrex.Result{rows: rows} = query!(Plenario.Repo, query, [])
#         [row | _] = rows
#
#         job_id = job.id()
#         meta_id = meta.id()
#         assert [^job_id, "erred", _, _, _, ^meta_id, _, _] = row
#       end
#     end
#   end
# end
