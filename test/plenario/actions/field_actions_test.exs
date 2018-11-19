defmodule Plenario.Testing.FieldActionsTest do
  use Plenario.Testing.DataCase

  alias Plenario.{
    DataSetActions,
    FieldActions,
    VirtualDateActions,
    VirtualPointActions
  }

  describe "list" do
    @tag :field
    test "all of them" do
      fields = FieldActions.list()
      assert length(fields) == 1
    end

    @tag :field
    test "with data set" do
      FieldActions.list()
      |> Enum.each(& refute Ecto.assoc_loaded?(&1.data_set))

      FieldActions.list(with_data_set: true)
      |> Enum.each(& assert Ecto.assoc_loaded?(&1.data_set))
    end

    @tag :field
    test "for data set", %{user: user, data_set: ds} do
      fields = FieldActions.list(for_data_set: ds)
      assert length(fields) == 1

      {:ok, other} = DataSetActions.create name: "Another DS",
        user: user,
        src_url: "https://example.com/1",
        src_type: "csv",
        socrata?: false

      fields = FieldActions.list(for_data_set: other)
      assert length(fields) == 0
    end
  end

  describe "get" do
    @tag :field
    test "with a known id", %{field: field} do
      {:ok, _} = FieldActions.get(field.id)
    end

    test "with an unknown id" do
      {:error, nil} = FieldActions.get(123456789)
    end
  end

  describe "get!" do
    @tag :field
    test "with a known id", %{field: field} do
      FieldActions.get!(field.id)
    end

    test "with an unknown id" do
      assert_raise Ecto.NoResultsError, fn ->
        FieldActions.get!(123456789)
      end
    end
  end

  describe "create" do
    @tag field: [name: "Some Field"]
    test "creates the col_name attribute", %{field: field} do
      assert field.col_name == "some_field"
    end

    @tag :field
    test "when parent data set isn't new", %{data_set: ds} do
      {:ok, ds} = DataSetActions.update(ds, state: "erred")

      {:error, changeset} = FieldActions.create name: "Not Gonna Happen",
        type: "jsonb",
        data_set: ds

      assert "cannot be created or edited once the parent data set's state is no longer \"new\"" in errors_on(changeset).base
    end
  end

  describe "update" do
    @tag :field
    test "changes col_name on name change", %{field: field} do
      {:ok, updated} = FieldActions.update(field, name: "Shiny New Name")
      assert updated.col_name == "shiny_new_name"
    end

    @tag :field
    test "when parent data set isn't new", %{data_set: ds, field: field} do
      {:ok, _} = DataSetActions.update(ds, state: "awaiting_approval")

      {:error, changeset} = FieldActions.update(field, type: "boolean")
      assert "cannot be created or edited once the parent data set's state is no longer \"new\"" in errors_on(changeset).base
    end
  end

  describe "delete" do
    @tag :field
    test "should delete all subordinate virtual dates", %{data_set: ds, field: field} do
      {:ok, _} = VirtualDateActions.create(data_set: ds, yr_field: field)

      {:ok, _} = FieldActions.delete(field)

      dates =
        VirtualDateActions.list(for_data_set: ds)
        |> Enum.filter(& &1.yr_field_id == field.id)
      assert length(dates) == 0
    end

    @tag :field
    test "should delete all subordinate virtual points", %{data_set: ds, field: field} do
      {:ok, _} = VirtualPointActions.create(data_set: ds, loc_field: field)

      {:ok, _} = FieldActions.delete(field)

      dates =
        VirtualPointActions.list(for_data_set: ds)
        |> Enum.filter(& &1.loc_field_id == field.id)
      assert length(dates) == 0
    end
  end
end
