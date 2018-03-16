defmodule Plenario.Testing.UniqueConstraintActionsTest do
  use Plenario.Testing.DataCase

  alias Plenario.Actions.{DataSetFieldActions, UniqueConstraintActions}

  setup %{meta: meta} do
    {:ok, pk} = DataSetFieldActions.create(meta, "id", "integer")

    {:ok, [pk: pk]}
  end

  test "new" do
    changeset = UniqueConstraintActions.new()
    refute changeset.action
  end

  describe "create" do
    test "with a meta struct", %{meta: meta, pk: pk} do
      {:ok, _} = UniqueConstraintActions.create(meta, [pk.id])
    end

    test "with a meta id", %{meta: meta, pk: pk} do
      {:ok, _} = UniqueConstraintActions.create(meta.id, [pk])
    end

    test "no fields", %{meta: meta} do
      {:error, _} = UniqueConstraintActions.create(meta, [])
    end
  end

  test "update", %{meta: meta, pk: pk} do
    {:ok, other} = DataSetFieldActions.create(meta, "other", "text")

    {:ok, uc} = UniqueConstraintActions.create(meta, [pk])

    constraint = UniqueConstraintActions.get(uc.id)
    {:ok, _} = UniqueConstraintActions.update(constraint, field_ids: [other.id])
  end
end
