defmodule PlenarioEtl.Testing.WorkerTest do
  use ExUnit.Case

  import Mock

  alias Plenario.ModelRegistry

  alias Plenario.Actions.{
    UserActions,
    MetaActions,
    DataSetFieldActions,
    VirtualPointFieldActions,
    DataSetActions
  }

  alias PlenarioEtl.Actions.EtlJobActions

  @csv_fixutre_path "test/fixtures/beach-lab-dna.csv"

  @fail_csv_fixutre_path "test/fixtures/beach-lab-dna-fail.csv"

  @shp_fixture_path "test/fixtures/Watersheds.zip"

  setup do
    # checkout a connection
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Plenario.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Plenario.Repo, {:shared, self()})

    # clear the registry
    ModelRegistry.clear()

    # setup a user
    {:ok, user} = UserActions.create("name", "email@example.com", "password")

    # setup a metas with fields, etc.
    {:ok, meta} = MetaActions.create("Chicago Beach Lab DNA Tests", user, "https://example.com/csv", "csv")
    {:ok, _} = DataSetFieldActions.create(meta, "DNA Test ID", "text")
    {:ok, _} = DataSetFieldActions.create(meta, "DNA Sample Timestamp", "timestamptz")
    {:ok, _} = DataSetFieldActions.create(meta, "Beach", "text")
    {:ok, _} = DataSetFieldActions.create(meta, "DNA Sample 1 Reading", "float")
    {:ok, _} = DataSetFieldActions.create(meta, "DNA Sample 2 Reading", "float")
    {:ok, _} = DataSetFieldActions.create(meta, "DNA Reading Mean", "float")
    {:ok, _} = DataSetFieldActions.create(meta, "Culture Test ID", "text")
    {:ok, _} = DataSetFieldActions.create(meta, "Culture Sample 1 Timestamp", "text")
    {:ok, _} = DataSetFieldActions.create(meta, "Culture Sample 1 Reading", "text")
    {:ok, _} = DataSetFieldActions.create(meta, "Culture Sample 2 Reading", "text")
    {:ok, _} = DataSetFieldActions.create(meta, "Culture Reading Mean", "text")
    {:ok, _} = DataSetFieldActions.create(meta, "Culture Note", "text")
    {:ok, _} = DataSetFieldActions.create(meta, "Culture Sample Interval", "text")
    {:ok, _} = DataSetFieldActions.create(meta, "Culture Sample 2 Timestamp", "text")
    {:ok, lat} = DataSetFieldActions.create(meta, "Latitude", "float")
    {:ok, lon} = DataSetFieldActions.create(meta, "Longitude", "float")
    {:ok, _} = DataSetFieldActions.create(meta, "Location", "text")
    {:ok, _} = VirtualPointFieldActions.create(meta, lat.id, lon.id)

    # bring up the data set tables
    :ok = DataSetActions.up!(meta)

    # return context
    {:ok, [meta: meta, user: user]}
  end

  defp mock_options_response(_), do: %HTTPoison.Response{status_code: 200}

  defp mock_get_response(path), do: %HTTPoison.Response{body: File.read!(path)}

  test "ingest csv", %{meta: meta} do
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

  test "ingest csv fail", %{meta: meta} do
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

  test "ingest shapefile", %{user: user} do
    with_mocks([
      {HTTPoison, [], options!: &mock_options_response/1},
      {HTTPoison, [], get!: &mock_get_response/1}
    ]) do
      {:ok, meta} = MetaActions.create("watersheds", user.id, @shp_fixture_path, "shp")

      :ok = DataSetActions.up!(meta)

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
end
