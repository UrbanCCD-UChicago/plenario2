defmodule Plenario2.Core.Changesets.VirtualDateFieldChangeset do
  import Ecto.Changeset

  def create(struct, params) do
    struct
    |> cast(params, [:year_field, :month_field, :day_field, :hour_field, :minute_field, :second_field, :meta_id])
    |> validate_required([:year_field, :meta_id])
    |> cast_assoc(:meta)
    |> _set_name()
  end

  ##
  # operations

  defp _set_name(changeset) do
    yr = get_field(changeset, :year_field)
    mo = get_field(changeset, :month_field)
    day = get_field(changeset, :day_field)
    hr = get_field(changeset, :hour_field)
    min = get_field(changeset, :minute_field)
    sec = get_field(changeset, :second_field)

    name =
      cond do
        yr != nil and mo != nil and day != nil and hr != nil and min != nil and sec != nil -> "_meta_date_#{yr}_#{mo}_#{day}_#{hr}_#{min}_#{sec}"
        yr != nil and mo != nil and day != nil and hr != nil and min != nil -> "_meta_date_#{yr}_#{mo}_#{day}_#{hr}_#{min}"
        yr != nil and mo != nil and day != nil and hr != nil -> "_meta_date_#{yr}_#{mo}_#{day}_#{hr}"
        yr != nil and mo != nil and day != nil -> "_meta_date_#{yr}_#{mo}_#{day}"
        yr != nil and mo != nil -> "_meta_date_#{yr}_#{mo}"
        yr != nil -> "_meta_date_#{yr}"
      end

    changeset |> put_change(:name, name)
  end
end
