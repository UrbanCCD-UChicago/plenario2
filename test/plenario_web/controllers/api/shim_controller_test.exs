defmodule PlenarioWeb.Api.ShimControllerTest do
  use ExUnit.Case
  use Phoenix.ConnTest

  import PlenarioWeb.Api.Utils, only: [truncate: 1]

  alias Plenario.{
    DataSetField,
    ModelRegistry,
    Repo
  }

  alias Plenario.Actions.{
    DataSetActions,
    DataSetFieldActions,
    MetaActions, 
    UniqueConstraintActions,
    UserActions,
    VirtualPointFieldActions
  }

  alias Plenario.Schemas.{
    DataSetField,
    Meta, 
    UniqueConstraint,
    User,
    VirtualPointField
  }

  alias PlenarioAot.{
    AotActions, 
    AotData, 
    AotMeta
  }

  @aot_fixture_path "test/fixtures/aot-chicago-future.json"
  @endpoint PlenarioWeb.Endpoint

  # Setting up the fixure data once _greatly_ reduces the test time. The 
  # downside is that in order to make this work you must be explicit about 
  # database connection ownership and you must also clean up tests yourself.
  setup_all do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, :auto)

    # Set up fixture data for /data-sets and /data-sets/:slug
    {:ok, user} = UserActions.create("API Test User", "test@example.com", "password")
    {:ok, meta} = MetaActions.create("API Test Dataset", user.id, "https://www.example.com", "csv")
    {:ok, pk} = DataSetFieldActions.create(meta.id, "pk", "integer")
    {:ok, _} = DataSetFieldActions.create(meta.id, "datetime", "timestamptz")
    {:ok, location} = DataSetFieldActions.create(meta.id, "location", "text")
    {:ok, _} = DataSetFieldActions.create(meta.id, "data", "text")
    {:ok, vpf} = VirtualPointFieldActions.create(meta, location.id)
    {:ok, _} = UniqueConstraintActions.create(meta.id, [pk.id])

    DataSetActions.up!(meta)

    # Insert 100 empty rows
    ModelRegistry.clear()
    model = ModelRegistry.lookup(meta.slug())
    (1..100) |> Enum.each(fn _ ->
      Repo.insert(%{model.__struct__ | datetime: "2500-01-01 00:00:00", location: "(50, 50)"})
    end)

    {:ok, meta} = AotActions.create_meta("Chicago", "https://example.com/")

    File.read!(@aot_fixture_path)
    |> Poison.decode!()
    |> Enum.map(fn obj -> AotActions.insert_data(meta, obj) end)

    AotActions.compute_and_update_meta_bbox(meta)
    AotActions.compute_and_update_meta_time_range(meta)

    # Registers a callback that runs once (because we're in setup_all) after 
    # all the tests have run. Use to clean up! If things screw up and this 
    # isn't called properly, `env MIX_ENV=test mix ecto.drop` (bash) is your 
    # friend.
    on_exit(fn ->
      # Check out again because this callback is run in another process.
      :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
      Ecto.Adapters.SQL.Sandbox.mode(Repo, :auto)
      truncate([DataSetField, Meta, UniqueConstraint, User, VirtualPointField, model])
      truncate([AotMeta, AotData])
    end)

    {:ok, %{
      meta: meta,
      vpf: vpf
    }}
  end

  test "GET /api/v1/data-sets __gt" do
  end

  test "GET /api/v1/data-sets __ge" do
  end

  test "GET /api/v1/data-sets __lt" do
  end

  test "GET /api/v1/data-sets __le" do
  end

  test "GET /api/v1/data-sets __eq" do
  end

  test "GET /v1/api/data-sets __gt" do
  end

  test "GET /v1/api/data-sets __ge" do
  end

  test "GET /v1/api/data-sets __lt" do
  end

  test "GET /v1/api/data-sets __le" do
  end

  test "GET /v1/api/data-sets __eq" do
  end

  test "GET /api/v1/data-sets/:slug __gt" do
  end

  test "GET /api/v1/data-sets/:slug __ge" do
  end

  test "GET /api/v1/data-sets/:slug __lt" do
  end

  test "GET /api/v1/data-sets/:slug __le" do
  end

  test "GET /api/v1/data-sets/:slug __eq" do
  end

  test "GET /v1/api/data-sets/:slug __gt" do
  end

  test "GET /v1/api/data-sets/:slug __ge" do
  end

  test "GET /v1/api/data-sets/:slug __lt" do
  end

  test "GET /v1/api/data-sets/:slug __le" do
  end

  test "GET /v1/api/data-sets/:slug __eq" do
  end
  
  test "GET /api/v1/aot __gt" do
  end

  test "GET /api/v1/aot __ge" do
  end

  test "GET /api/v1/aot __lt" do
  end

  test "GET /api/v1/aot __le" do
  end

  test "GET /api/v1/aot __eq" do
  end

  test "GET /v1/api/aot __gt" do
  end

  test "GET /v1/api/aot __ge" do
  end

  test "GET /v1/api/aot __lt" do
  end

  test "GET /v1/api/aot __le" do
  end

  test "GET /v1/api/aot __eq" do
  end
end