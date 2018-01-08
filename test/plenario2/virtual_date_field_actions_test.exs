defmodule VirtualDateFieldActionsTests do
  use Plenario2.DataCase, async: true

  alias Plenario2.Actions.{DataSetFieldActions, VirtualDateFieldActions}

  setup context do
    DataSetFieldActions.create(context.meta.id, "year", "integer")
    DataSetFieldActions.create(context.meta.id, "month", "integer")
    DataSetFieldActions.create(context.meta.id, "day", "integer")
    DataSetFieldActions.create(context.meta.id, "hour", "integer")
    DataSetFieldActions.create(context.meta.id, "minute", "integer")
    DataSetFieldActions.create(context.meta.id, "second", "integer")

    context
  end

  test "create virtual date field", context do
    {:ok, field} = VirtualDateFieldActions.create(context.meta.id, "year")
    assert field.name == "_meta_date_year"

    {:ok, field} = VirtualDateFieldActions.create(context.meta.id, "year", "month")
    assert field.name == "_meta_date_year_month"

    {:ok, field} = VirtualDateFieldActions.create(context.meta.id, "year", "month", "day")
    assert field.name == "_meta_date_year_month_day"

    {:ok, field} = VirtualDateFieldActions.create(context.meta.id, "year", "month", "day", "hour")
    assert field.name == "_meta_date_year_month_day_hour"

    {:ok, field} = VirtualDateFieldActions.create(context.meta.id, "year", "month", "day", "hour", "minute")
    assert field.name == "_meta_date_year_month_day_hour_minute"

    {:ok, field} = VirtualDateFieldActions.create(context.meta.id, "year", "month", "day", "hour", "minute", "second")
    assert field.name == "_meta_date_year_month_day_hour_minute_second"
  end

  test "creating a virtual field with a field that isn't registered to the meta fails", context do
    {:error, _} = VirtualDateFieldActions.create(context.meta.id, "some_unknown_field")
  end

  test "list virtual date fields for meta", context do
    VirtualDateFieldActions.create(context.meta.id, "year")
    assert length(VirtualDateFieldActions.list_for_meta(context.meta)) == 1
  end

  test "delete virtual date field", context do
    {:ok, field} = VirtualDateFieldActions.create(context.meta.id, "year")
    assert length(VirtualDateFieldActions.list_for_meta(context.meta)) == 1

    VirtualDateFieldActions.delete(field)
    assert length(VirtualDateFieldActions.list_for_meta(context.meta)) == 0
  end
end
