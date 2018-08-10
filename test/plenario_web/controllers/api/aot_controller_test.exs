defmodule PlenarioWeb.Api.AotControllerTest do
  use ExUnit.Case

  use Phoenix.ConnTest

  import PlenarioWeb.Router.Helpers

  alias Plenario.Repo

  alias PlenarioAot.AotActions

  @endpoint PlenarioWeb.Endpoint

  @fixture "test/fixtures/aot-chicago.json"

  @total_records 10

  setup do
    Ecto.Adapters.SQL.Sandbox.checkout(Plenario.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Plenario.Repo, {:shared, self()})

    {:ok, meta} = AotActions.create_meta("Chicago", "https://example.com/")

    Repo.transaction(fn ->
      File.read!(@fixture)
      |> Poison.decode!()
      |> Enum.map(fn obj -> {:ok, _} = AotActions.insert_data(meta, obj) end)
    end)

    AotActions.compute_and_update_meta_bbox(meta)
    AotActions.compute_and_update_meta_time_range(meta)

    {:ok, conn: build_conn(), meta: meta}
  end

  describe "GET :get naive" do
    test "applies page", %{conn: conn} do
      res =
        conn
        |> get(aot_path(conn, :get))
        |> json_response(:ok)

      assert res["meta"]["params"]["page"] == 1
    end

    test "applies page size", %{conn: conn} do
      res =
        conn
        |> get(aot_path(conn, :get))
        |> json_response(:ok)

      assert res["meta"]["params"]["page_size"] == 200
    end

    test "applies order", %{conn: conn} do
      res =
        conn
        |> get(aot_path(conn, :get))
        |> json_response(:ok)

      assert res["meta"]["params"]["order_by"] == %{"desc" => "timestamp"}
    end

    test "applies window", %{conn: conn} do
      res =
        conn
        |> get(aot_path(conn, :get))
        |> json_response(:ok)

      window = res["meta"]["params"]["window"]
      {:ok, _} = Timex.parse(window, "%Y-%m-%dT%H:%M:%S", :strftime)
    end
  end

  describe "GET :get" do
    test "filter with a known `network_name` will yield results", %{conn: conn, meta: meta} do
      # flaky test, requires sleep to let db settle
      Process.sleep(1000)

      res =
        conn
        |> get(aot_path(conn, :get, %{network_name: meta.network_name}))
        |> json_response(:ok)

      assert length(res["data"]) == @total_records
    end

    test "filter with an unknown `network_name` will yield 0 results", %{conn: conn} do
      res =
        conn
        |> get(aot_path(conn, :get, %{network_name: "nada"}))
        |> json_response(:ok)

      assert length(res["data"]) == 0
    end

    test "filter with a known `network_name` and an unknown `node_id` will yield 0 results", %{
      conn: conn,
      meta: meta
    } do
      res =
        conn
        |> get(aot_path(conn, :get, %{network_name: meta.network_name, node_id: "nope"}))
        |> json_response(:ok)

      assert length(res["data"]) == 0
    end

    test "filter with multiple `good node_id`s will yield results", %{conn: conn} do
      # flaky test, requires sleep to let db settle
      Process.sleep(1000)

      # path = "/api/v2/aot?node_id[]=080&node_id[]=081"
      res =
        conn
        |> get(aot_path(conn, :get, %{node_id: ["080", "081"]}))
        |> json_response(:ok)

      assert length(res["data"]) == 9
    end
  end
end
