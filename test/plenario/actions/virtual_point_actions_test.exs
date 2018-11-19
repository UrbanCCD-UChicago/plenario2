defmodule Plenario.Testing.VirtualPointActionsTest do
  use Plenario.Testing.DataCase

  alias Plenario.{
    DataSetActions,
    VirtualPointActions
  }

  describe "list" do
    @tag :virtual_point
    test "all of them" do
      points = VirtualPointActions.list()
      assert length(points) == 1
    end

    @tag :virtual_point
    test "with data set" do
      VirtualPointActions.list()
      |> Enum.each(& refute Ecto.assoc_loaded?(&1.data_set))

      VirtualPointActions.list(with_data_set: true)
      |> Enum.each(& assert Ecto.assoc_loaded?(&1.data_set))
    end

    @tag :virtual_point
    test "for data set", %{user: user, data_set: ds} do
      points = VirtualPointActions.list(for_data_set: ds)
      assert length(points) == 1

      {:ok, other} = DataSetActions.create name: "Another DS",
        user: user,
        src_url: "https://example.com/1",
        src_type: "csv",
        socrata?: false

      points = VirtualPointActions.list(for_data_set: other)
      assert length(points) == 0
    end

    @tag :virtual_point
    test "with fields" do
      VirtualPointActions.list(with_fields: true)
      |> Enum.each(& assert Ecto.assoc_loaded?(&1.loc_field))
    end
  end

  describe "get" do
    @tag :virtual_point
    test "with a known id", %{virtual_point: pt} do
      {:ok, _} = VirtualPointActions.get(pt.id)
    end

    test "with an unknown id" do
      {:error, nil} = VirtualPointActions.get(123456789)
    end
  end

  describe "get!" do
    @tag :virtual_point
    test "with a known id", %{virtual_point: pt} do
      VirtualPointActions.get!(pt.id)
    end

    test "with an unknown id" do
      assert_raise Ecto.NoResultsError, fn ->
        VirtualPointActions.get!(123456789)
      end
    end
  end

  describe "create" do
    @tag :virtual_point
    test "sets the col_name attribute", %{data_set: ds, field: field, virtual_point: pt} do
      assert pt.col_name == "vp_#{ds.id}_#{field.id}"
    end

    @tag field: [name: "loc"]
    test "with loc, lon and lat set", %{data_set: ds, field: loc} do
      lon = create_field(%{data_set: ds}, name: "lon")
      lat = create_field(%{data_set: ds}, name: "lat")

      {:error, changeset} = VirtualPointActions.create data_set: ds,
        loc_field: loc, lon_field: lon, lat_field: lat

      assert "either location or longitude and latitude must be set -- they are mutually exclusive" in errors_on(changeset).loc_field_id
      assert "either location or longitude and latitude must be set -- they are mutually exclusive" in errors_on(changeset).lon_field_id
      assert "either location or longitude and latitude must be set -- they are mutually exclusive" in errors_on(changeset).lat_field_id
    end

    @tag :field
    test "when parent meta isn't new", %{data_set: ds, field: field} do
      {:ok, ds} = DataSetActions.update(ds, state: "awaiting_approval")

      {:error, changeset} = VirtualPointActions.create(data_set: ds, loc_field: field)

      assert "cannot be created or edited once the parent data set's state is no longer \"new\"" in errors_on(changeset).base
    end
  end

  describe "update" do
    @tag :virtual_point
    test "changes the col_name attribute when the ref'd fields are changed", %{data_set: ds, virtual_point: pt} do
      field = create_field(%{data_set: ds}, name: "new loc")

      {:ok, updated} = VirtualPointActions.update(pt, loc_field: field)
      assert updated.col_name == "vp_#{ds.id}_#{field.id}"
    end

    @tag :virtual_point
    test "add lon and lat to a vpoint with loc already set", %{data_set: ds, virtual_point: pt} do
      lon = create_field(%{data_set: ds}, name: "lon")
      lat = create_field(%{data_set: ds}, name: "lat")

      {:error, changeset} = VirtualPointActions.update(pt, lon_field: lon, lat_field: lat)

      assert "either location or longitude and latitude must be set -- they are mutually exclusive" in errors_on(changeset).loc_field_id
      assert "either location or longitude and latitude must be set -- they are mutually exclusive" in errors_on(changeset).lon_field_id
      assert "either location or longitude and latitude must be set -- they are mutually exclusive" in errors_on(changeset).lat_field_id
    end

    @tag :virtual_point
    test "when parent meta isn't new", %{data_set: ds, virtual_point: pt} do
      field = create_field(%{data_set: ds}, name: "new loc")

      {:ok, _} = DataSetActions.update(ds, state: "ready")

      {:error, changeset} = VirtualPointActions.update(pt, loc_field: field)

      assert "cannot be created or edited once the parent data set's state is no longer \"new\"" in errors_on(changeset).base
    end
  end
end
