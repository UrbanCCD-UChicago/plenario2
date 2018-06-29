defmodule PlenarioEtl.Testing.WorkflowTest do
  use Plenario.Testing.EtlCase

  import Ecto.Query

  import Mock

  alias Plenario.{ModelRegistry, Repo}

  alias Plenario.Actions.{MetaActions, VirtualPointFieldActions}

  alias PlenarioEtl

  @fixture "test/fixtures/beach-lab-dna.csv"

  @num_records 2936

  @row_id 1

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end

  defp mock_options!(_), do: %HTTPoison.Response{status_code: 200}

  test "data is loaded into view", %{meta: meta, bypass: bypass} do
    with_mock HTTPoison, options!: &mock_options!/1 do
      {:ok, _} = MetaActions.update(meta, source_url: "http://localhost:#{bypass.port}/", refresh_starts_on: ~N[1999-12-31 23:59:59])
    end
    meta = MetaActions.get(meta.id)
    {:ok, _} = MetaActions.submit_for_approval(meta)
    meta = MetaActions.get(meta.id)
    {:ok, _} = MetaActions.approve(meta)

    Bypass.expect(bypass, fn conn ->
      Plug.Conn.send_file(conn, 200, @fixture)
    end)

    PlenarioEtl.import_data_sets()
    Process.sleep(1000)

    model = ModelRegistry.lookup(meta.slug)

    records = Repo.all(from m in model)
    assert length(records) == @num_records

    first = Repo.one(from m in model, where: m.row_id == @row_id)
    assert Map.get(first, :"DNA Reading Mean") == 79.7
    assert Map.get(first, :"DNA Sample 1 Reading") == 39.0
    assert Map.get(first, :"DNA Sample 2 Reading") == 163.0
    assert Map.get(first, :"DNA Sample Timestamp") == ~N[2016-08-05 12:35:00.000000]
    assert Map.get(first, :Latitude) == 41.9655
    assert Map.get(first, :Longitude) == -87.6385

    VirtualPointFieldActions.list(for_meta: meta)
    |> Enum.each(fn vpf ->
      assert Map.get(first, String.to_atom(vpf.name)) == %Geo.Point{
        coordinates: {-87.6385, 41.9655},
        srid: 4326
      }
    end)
  end

  test "Meta's next import is updated", %{meta: meta, bypass: bypass} do
    with_mock HTTPoison, options!: &mock_options!/1 do
      {:ok, _} = MetaActions.update(meta, source_url: "http://localhost:#{bypass.port}/", refresh_starts_on: ~N[1999-12-31 23:59:59])
    end
    meta = MetaActions.get(meta.id)
    {:ok, _} = MetaActions.submit_for_approval(meta)
    meta = MetaActions.get(meta.id)
    {:ok, _} = MetaActions.approve(meta)

    Bypass.expect(bypass, fn conn ->
      Plug.Conn.send_file(conn, 200, @fixture)
    end)

    PlenarioEtl.import_data_sets()
    Process.sleep(1000)

    meta = MetaActions.get(meta.id)
    refute is_nil(meta.next_import)
  end

  test "Meta's latest import is updated", %{meta: meta, bypass: bypass} do
    with_mock HTTPoison, options!: &mock_options!/1 do
      {:ok, _} = MetaActions.update(meta, source_url: "http://localhost:#{bypass.port}/", refresh_starts_on: ~N[1999-12-31 23:59:59])
    end
    meta = MetaActions.get(meta.id)
    {:ok, _} = MetaActions.submit_for_approval(meta)
    meta = MetaActions.get(meta.id)
    {:ok, _} = MetaActions.approve(meta)

    Bypass.expect(bypass, fn conn ->
      Plug.Conn.send_file(conn, 200, @fixture)
    end)

    PlenarioEtl.import_data_sets()
    Process.sleep(2000)

    meta = MetaActions.get(meta.id)
    refute is_nil(meta.latest_import)
  end
end
