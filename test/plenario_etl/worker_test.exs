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

  @fail_json_fixture_path "test/fixtures/aot-chicago-fail.json"

  @csv_fixutre_path "test/fixtures/beach-lab-dna.csv"

  @corrupt_csv_fixutre_path "test/fixtures/beach-lab-dna-corrupted.csv"

  @fail_csv_fixutre_path "test/fixtures/beach-lab-dna-fail.csv"

  setup do
    # checkout a connection
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Plenario.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Plenario.Repo, {:shared, self()})

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

  defp mock_options_response(_), do: %HTTPoison.Response{status_code: 200}

  defp mock_get_response(path), do: %HTTPoison.Response{body: File.read!(path)}

  test "ingest csv", %{csv_meta: meta} do
    with_mock HTTPoison, options!: &mock_options_response/1 do
      # set meta's source url so we get the right fixture
      {:ok, _} = MetaActions.update(meta, source_url: @csv_fixutre_path)
    end

    with_mock HTTPoison, get!: &mock_get_response/1 do
      # ingest the data set
      {job, task} = PlenarioEtl.ingest(meta)

      # wait for the job to finish
      Task.await(task, 300_000)

      # get the refreshed job from the database and ensure its success
      job = EtlJobActions.get(job.id)
      assert job.state == "succeeded"
      refute job.error_message
    end
  end

  test "ingest json", %{json_meta: meta} do
    with_mock HTTPoison, options!: &mock_options_response/1 do
      # set meta's source url so we get the right fixture
      {:ok, _} = MetaActions.update(meta, source_url: @json_fixture_path)
    end

    with_mock HTTPoison, get!: &mock_get_response/1 do
      # ingest the data set
      {job, task} = PlenarioEtl.ingest(meta)

      # wait for the job to finish
      Task.await(task, 300_000)

      # get the refreshed job from the database and ensure its success
      job = EtlJobActions.get(job.id)
      assert job.state == "succeeded"
      refute job.error_message
    end
  end

  test "ingest csv partial success", %{csv_meta: meta} do
    with_mock HTTPoison, options!: &mock_options_response/1 do
      # set meta's source url so we get the right fixture
      {:ok, _} = MetaActions.update(meta, source_url: @corrupt_csv_fixutre_path)
    end

    with_mock HTTPoison, get!: &mock_get_response/1 do
      # ingest the data set
      {job, task} = PlenarioEtl.ingest(meta)

      # wait for the job to finish
      Task.await(task, 300_000)

      # get the refreshed job from the database and ensure its success
      job = EtlJobActions.get(job.id)
      assert job.state == "partial_success"
      assert job.error_message
    end
  end

  test "ingest json partial success", %{json_meta: meta} do
    with_mock HTTPoison, options!: &mock_options_response/1 do
      # set meta's source url so we get the right fixture
      {:ok, _} = MetaActions.update(meta, source_url: @corrupt_json_fixture_path)
    end

    with_mock HTTPoison, get!: &mock_get_response/1 do
      # ingest the data set
      {job, task} = PlenarioEtl.ingest(meta)

      # wait for the job to finish
      Task.await(task, 300_000)

      # get the refreshed job from the database and ensure its success
      job = EtlJobActions.get(job.id)
      assert job.state == "partial_success"
      assert job.error_message
    end
  end

  test "ingest csv fail", %{csv_meta: meta} do
    with_mock HTTPoison, options!: &mock_options_response/1 do
      # set meta's source url so we get the right fixture
      {:ok, _} = MetaActions.update(meta, source_url: @fail_csv_fixutre_path)
    end

    with_mock HTTPoison, get!: &mock_get_response/1 do
      # ingest the data set
      {job, task} = PlenarioEtl.ingest(meta)

      # wait for the job to finish
      Task.await(task, 300_000)

      # get the refreshed job from the database and ensure its success
      job = EtlJobActions.get(job.id)
      assert job.state == "erred"
      assert job.error_message
    end
  end

  test "ingest json fail", %{json_meta: meta} do
    with_mock HTTPoison, options!: &mock_options_response/1 do
      # set meta's source url so we get the right fixture
      {:ok, _} = MetaActions.update(meta, source_url: @fail_json_fixture_path)
    end

    with_mock HTTPoison, get!: &mock_get_response/1 do
      # ingest the data set
      {job, task} = PlenarioEtl.ingest(meta)

      # wait for the job to finish
      Task.await(task, 300_000)

      # get the refreshed job from the database and ensure its success
      job = EtlJobActions.get(job.id)
      assert job.state == "erred"
      assert job.error_message
    end
  end
end
