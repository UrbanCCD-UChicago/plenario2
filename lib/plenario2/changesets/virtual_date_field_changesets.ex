defmodule Plenario2.Changesets.VirtualDateFieldChangesets do
  import Ecto.Changeset
  alias Plenario2.Actions.{MetaActions, DataSetFieldActions}

  def create(struct, params) do
    struct
    |> cast(params, [
         :year_field,
         :month_field,
         :day_field,
         :hour_field,
         :minute_field,
         :second_field,
         :meta_id
       ])
    |> validate_required([:year_field, :meta_id])
    |> validate_fields()
    |> cast_assoc(:meta)
    |> set_name()
  end

  def blank(struct) do
    struct
    |> cast(%{}, [
         :year_field,
         :month_field,
         :day_field,
         :hour_field,
         :minute_field,
         :second_field,
         :meta_id
       ])
   end

  ##
  # operations

  defp set_name(changeset) do
    yr = get_field(changeset, :year_field)
    mo = get_field(changeset, :month_field)
    day = get_field(changeset, :day_field)
    hr = get_field(changeset, :hour_field)
    min = get_field(changeset, :minute_field)
    sec = get_field(changeset, :second_field)

    name =
      cond do
        yr != nil and mo != nil and day != nil and hr != nil and min != nil and sec != nil ->
          "_meta_date_#{yr}_#{mo}_#{day}_#{hr}_#{min}_#{sec}"

        yr != nil and mo != nil and day != nil and hr != nil and min != nil ->
          "_meta_date_#{yr}_#{mo}_#{day}_#{hr}_#{min}"

        yr != nil and mo != nil and day != nil and hr != nil ->
          "_meta_date_#{yr}_#{mo}_#{day}_#{hr}"

        yr != nil and mo != nil and day != nil ->
          "_meta_date_#{yr}_#{mo}_#{day}"

        yr != nil and mo != nil ->
          "_meta_date_#{yr}_#{mo}"

        yr != nil ->
          "_meta_date_#{yr}"
      end

    changeset |> put_change(:name, name)
  end

  ##
  # validations

  defp validate_fields(changeset) do
    meta_id = get_field(changeset, :meta_id)
    year = get_field(changeset, :year_field)
    month = get_field(changeset, :month_field)
    day = get_field(changeset, :day_field)
    hour = get_field(changeset, :hour_field)
    minute = get_field(changeset, :minute_field)
    second = get_field(changeset, :second_field)
    field_namez = [year, month, day, hour, minute, second]

    meta = MetaActions.get_from_id(meta_id)
    fields = DataSetFieldActions.list_for_meta(meta)
    known_field_names = for f <- fields, do: f.name

    field_names = Enum.filter(field_namez, fn (name) -> name != nil end)
    is_subset = field_names |> Enum.all?(fn (name) -> Enum.member?(known_field_names, name) end)
    if is_subset do
      changeset
    else
      changeset |> add_error(:fields, "Field names must exist as registered fields of the data set")
    end
  end
end
