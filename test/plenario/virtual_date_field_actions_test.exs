defmodule Plenario.Testing.VirtualDateFieldActionsTest do
  use Plenario.Testing.DataCase, async: true

  alias Plenario.Actions.{DataSetFieldActions, VirtualDateFieldActions}

  setup %{meta: meta} do
    {:ok, yr} = DataSetFieldActions.create(meta, "year", "integer")
    {:ok, mo} = DataSetFieldActions.create(meta, "month", "integer")
    {:ok, day} = DataSetFieldActions.create(meta, "day", "integer")
    {:ok, hr} = DataSetFieldActions.create(meta, "hour", "integer")
    {:ok, mi} = DataSetFieldActions.create(meta, "minute", "integer")
    {:ok, sec} = DataSetFieldActions.create(meta, "second", "integer")

    {:ok, [yr: yr, mo: mo, day: day, hr: hr, mi: mi, sec: sec]}
  end

  test "new" do
    changeset = VirtualDateFieldActions.new()

    assert changeset.action == nil
    refute changeset.valid?
  end

  describe "create" do
    test "with meta id and yr id", %{meta: meta, yr: yr} do
      {:ok, f} = VirtualDateFieldActions.create(meta.id, yr.id)

      field = VirtualDateFieldActions.get(f.id)
      assert field.year_field_id == yr.id
      refute field.month_field_id
    end

    test "with meta id, yr id, opts", %{meta: meta, yr: yr, mo: mo, day: day, hr: hr, mi: mi, sec: sec} do
      {:ok, f} =
        VirtualDateFieldActions.create(
          meta.id, yr.id, month_field_id: mo.id, day_field_id: day.id,
          hour_field_id: hr.id, minute_field_id: mi.id, second_field_id: sec.id
        )

      field = VirtualDateFieldActions.get(f.id)
      assert field.year_field_id == yr.id
      assert field.month_field_id == mo.id
      assert field.day_field_id == day.id
      assert field.hour_field_id == hr.id
      assert field.minute_field_id == mi.id
      assert field.second_field_id == sec.id
    end
  end

  test "update", %{meta: meta, yr: yr, mo: mo} do
    {:ok, f} = VirtualDateFieldActions.create(meta.id, yr.id)

    field = VirtualDateFieldActions.get(f.id)
    {:ok, f} = VirtualDateFieldActions.update(field, month_field_id: mo.id)

    field = VirtualDateFieldActions.get(f.id)
    assert field.year_field_id == yr.id
    assert field.month_field_id == mo.id
  end

  test "get", %{meta: meta, yr: yr} do
    {:ok, f} = VirtualDateFieldActions.create(meta.id, yr.id)

    field = VirtualDateFieldActions.get(f.id)
    assert field.id == f.id
  end
end
