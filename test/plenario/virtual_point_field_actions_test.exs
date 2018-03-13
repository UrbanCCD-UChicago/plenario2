defmodule Plenario.Testing.VirtualPointFieldActionsTest do
  use Plenario.Testing.DataCase 

  alias Plenario.Actions.{DataSetFieldActions, VirtualPointFieldActions}

  setup %{meta: meta} do
    {:ok, lat} = DataSetFieldActions.create(meta, "lat", "float")
    {:ok, lon} = DataSetFieldActions.create(meta, "lon", "float")
    {:ok, loc} = DataSetFieldActions.create(meta, "loc", "text")

    {:ok, [lat: lat, lon: lon, loc: loc]}
  end

  test "new" do
    changeset = VirtualPointFieldActions.new()

    assert changeset.action == nil
  end

  describe "create" do
    test "with lat lon", %{meta: meta, lat: lat, lon: lon} do
      {:ok, f} = VirtualPointFieldActions.create(meta.id, lat.id, lon.id)

      field = VirtualPointFieldActions.get(f.id)
      assert field.lat_field_id == lat.id
      assert field.lon_field_id == lon.id
      refute field.loc_field_id
    end

    test "with loc", %{meta: meta, loc: loc} do
      {:ok, f} = VirtualPointFieldActions.create(meta.id, loc.id)

      field = VirtualPointFieldActions.get(f.id)
      refute field.lat_field_id
      refute field.lon_field_id
      assert field.loc_field_id == loc.id
    end
  end

  describe "update" do
    test "substitute a field", %{meta: meta, lat: lat, lon: lon, loc: loc} do
      {:ok, f} = VirtualPointFieldActions.create(meta.id, lat.id, lon.id)

      field = VirtualPointFieldActions.get(f.id)
      {:ok, _} = VirtualPointFieldActions.update(field, lon_field_id: loc.id)
    end

    test "lat and lon are the same", %{meta: meta, lat: lat, lon: lon} do
      {:ok, f} = VirtualPointFieldActions.create(meta.id, lat.id, lon.id)

      field = VirtualPointFieldActions.get(f.id)
      {:error, _} = VirtualPointFieldActions.update(field, lon_field_id: lat.id)
    end

    test "set all three", %{meta: meta, lat: lat, lon: lon, loc: loc} do
      {:ok, f} = VirtualPointFieldActions.create(meta.id, lat.id, lon.id)

      field = VirtualPointFieldActions.get(f.id)
      {:error, _} = VirtualPointFieldActions.update(field, loc_field_id: loc.id)
    end
  end
end
