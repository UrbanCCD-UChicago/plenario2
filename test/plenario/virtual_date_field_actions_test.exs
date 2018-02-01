defmodule VirtualDateFieldActionsTests do
  use Plenario.DataCase, async: true

  alias Plenario.Actions.{DataSetFieldActions, VirtualDateFieldActions, MetaActions}

  alias PlenarioAuth.UserActions

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

    {:ok, field} =
      VirtualDateFieldActions.create(context.meta.id, "year", "month", "day", "hour", "minute")

    assert field.name == "_meta_date_year_month_day_hour_minute"

    {:ok, field} =
      VirtualDateFieldActions.create(
        context.meta.id,
        "year",
        "month",
        "day",
        "hour",
        "minute",
        "second"
      )

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

  describe "update a virtual date field" do
    test "when the meta hasn't been approved yet", context do
      {:ok, field} = VirtualDateFieldActions.create(context.meta.id, "year")

      {:ok, field} = VirtualDateFieldActions.update(field, %{year_field: "month"})
      assert field.year_field == "month"
      assert field.name == "_meta_date_month"
    end

    test "with bad data", context do
      {:ok, field} = VirtualDateFieldActions.create(context.meta.id, "year")
      {:error, _} = VirtualDateFieldActions.update(field, %{month_field: "nope"})
    end

    test "when the meta has already been approved", context do
      {:ok, field} = VirtualDateFieldActions.create(context.meta.id, "year")

      UserActions.promote_to_admin(context.user)
      user = UserActions.get_from_id(context.user.id)
      meta = MetaActions.get(context.meta.id, with_user: true)

      MetaActions.submit_for_approval(meta)
      meta = MetaActions.get(meta.id, with_user: true)
      MetaActions.approve(meta, user)
      meta = MetaActions.get(meta.id, with_user: true)
      assert meta.state == "ready"

      {:error, error} = VirtualDateFieldActions.update(field, %{year_field: "nope"})

      assert error.errors == [
               name:
                 {"Cannot alter any fields after the parent data set has been approved. If you need to update this field, please contact the administrators.",
                  []},
               fields: {"Field names must exist as registered fields of the data set", []}
             ]
    end
  end
end
