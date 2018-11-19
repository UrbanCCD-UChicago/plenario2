defmodule Plenario.Testing.VirtualDateActionsTest do
  use Plenario.Testing.DataCase

  alias Plenario.{
    DataSetActions,
    VirtualDateActions
  }

  describe "list" do
    @tag :virtual_date
    test "all of them" do
      points = VirtualDateActions.list()
      assert length(points) == 1
    end

    @tag :virtual_date
    test "with data set" do
      VirtualDateActions.list()
      |> Enum.each(& refute Ecto.assoc_loaded?(&1.data_set))

      VirtualDateActions.list(with_data_set: true)
      |> Enum.each(& assert Ecto.assoc_loaded?(&1.data_set))
    end

    @tag :virtual_date
    test "for data set", %{user: user, data_set: ds} do
      points = VirtualDateActions.list(for_data_set: ds)
      assert length(points) == 1

      {:ok, other} = DataSetActions.create name: "Another DS",
        user: user,
        src_url: "https://example.com/1",
        src_type: "csv",
        socrata?: false

      points = VirtualDateActions.list(for_data_set: other)
      assert length(points) == 0
    end

    @tag :virtual_date
    test "with fields" do
      VirtualDateActions.list(with_fields: true)
      |> Enum.each(& assert Ecto.assoc_loaded?(&1.yr_field))
    end
  end

  describe "get" do
    @tag :virtual_date
    test "with a known id", %{virtual_date: date} do
      {:ok, _} = VirtualDateActions.get(date.id)
    end

    test "with an unknown id" do
      {:error, nil} = VirtualDateActions.get(123456789)
    end
  end

  describe "get!" do
    @tag :virtual_date
    test "with a known id", %{virtual_date: date} do
      VirtualDateActions.get!(date.id)
    end

    test "with an unknown id" do
      assert_raise Ecto.NoResultsError, fn ->
        VirtualDateActions.get!(123456789)
      end
    end
  end

  describe "create" do
    @tag :virtual_date
    test "sets the col_name attribute", %{data_set: ds, field: field, virtual_date: date} do
      assert date.col_name == "vd_#{ds.id}_#{field.id}"
    end

    @tag :field
    test "when parent meta isn't new", %{data_set: ds, field: field} do
      {:ok, ds} = DataSetActions.update(ds, state: "awaiting_approval")

      {:error, changeset} = VirtualDateActions.create(data_set: ds, loc_field: field)

      assert "cannot be created or edited once the parent data set's state is no longer \"new\"" in errors_on(changeset).base
    end
  end

  describe "update" do
    @tag :virtual_date
    test "changes the col_name attribute when the ref'd fields are changed", %{data_set: ds, virtual_date: date} do
      field = create_field(%{data_set: ds}, name: "new field")

      {:ok, updated} = VirtualDateActions.update(date, mo_field: field)
      assert updated.col_name == "#{date.col_name}_#{field.id}"
    end

    @tag :virtual_date
    test "when parent meta isn't new", %{data_set: ds, virtual_date: date} do
      field = create_field(%{data_set: ds}, name: "new loc")

      {:ok, _} = DataSetActions.update(ds, state: "ready")

      {:error, changeset} = VirtualDateActions.update(date, loc_field: field)

      assert "cannot be created or edited once the parent data set's state is no longer \"new\"" in errors_on(changeset).base
    end
  end
end
