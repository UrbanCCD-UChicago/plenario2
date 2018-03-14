defmodule Plenario.Testing.DataSetFieldActionsTest do
  use Plenario.Testing.DataCase 

  alias Plenario.Actions.{DataSetFieldActions, MetaActions}

  test "new" do
    changeset = DataSetFieldActions.new()

    assert changeset.action == nil
  end

  describe "create" do
    test "with meta struct", %{meta: meta} do
      {:ok, _} = DataSetFieldActions.create(meta, "id", "integer")
    end

    test "with meta id", %{meta: meta} do
      {:ok, _} = DataSetFieldActions.create(meta.id, "id", "integer")
    end
  end

  describe "update" do
    setup context do
      {:ok, field} = DataSetFieldActions.create(context.meta.id, "id", "integer")

      {:ok, [field: field]}
    end

    test "name", %{field: field} do
      {:ok, _} = DataSetFieldActions.update(field, name: "set id")

      field = DataSetFieldActions.get(field.id)
      assert field.name == "set id"
    end

    test "type", %{field: field} do
      # good
      {:ok, _} = DataSetFieldActions.update(field, type: "text")
      field = DataSetFieldActions.get(field.id)
      assert field.type == "text"

      # bad
      {:error, _} = DataSetFieldActions.update(field, type: "i dunno")
    end

    test "name and type", %{field: field} do
      {:ok, _} = DataSetFieldActions.update(field, name: "different", type: "text")

      field = DataSetFieldActions.get(field.id)
      assert field.name == "different"
      assert field.type == "text"
    end

    test "when meta is no longer new", %{meta: meta, field: field} do
      {:ok, _} = MetaActions.submit_for_approval(meta)

      {:error, _} = DataSetFieldActions.update(field, name: "not gonna happen")
    end
  end

  describe "list" do
    test "for_meta opt", %{meta: meta} do
      {:ok, _} = DataSetFieldActions.create(meta.id, "id", "integer")

      fields = DataSetFieldActions.list(for_meta: meta)
      assert length(fields) == 1
    end
  end

  test "get", %{meta: meta} do
    {:ok, field} = DataSetFieldActions.create(meta.id, "id", "integer")

    found = DataSetFieldActions.get(field.id)
    assert found.name == field.name
    assert found.type == field.type
  end
end
