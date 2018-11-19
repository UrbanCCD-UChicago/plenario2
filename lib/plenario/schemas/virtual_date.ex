defmodule Plenario.VirtualDate do
  use Ecto.Schema

  import Ecto.Changeset

  import Plenario.SchemaUtils

  alias Plenario.{
    DataSet,
    Field,
    VirtualDate
  }

  schema "virtual_dates" do
    field :col_name, :string
    belongs_to :data_set, DataSet
    belongs_to :yr_field, Field
    belongs_to :mo_field, Field
    belongs_to :day_field, Field
    belongs_to :hr_field, Field
    belongs_to :min_field, Field
    belongs_to :sec_field, Field
  end

  defimpl Phoenix.HTML.Safe, for: VirtualDate, do: def to_iodata(date), do: date.col_name

  @attrs ~w|data_set_id yr_field_id mo_field_id day_field_id hr_field_id min_field_id sec_field_id|a

  @reqd ~w|data_set_id yr_field_id|a

  @doc false
  def changeset(virtual_date, attrs) do
    virtual_date
    |> cast(attrs, @attrs)
    |> validate_required(@reqd)
    |> validate_data_set_state()
    |> put_col_name()
    |> unique_constraint(:base, name: :vd_uniq)
    |> foreign_key_constraint(:data_set_id)
    |> foreign_key_constraint(:yr_field_id)
    |> foreign_key_constraint(:mo_field_id)
    |> foreign_key_constraint(:day_field_id)
    |> foreign_key_constraint(:hr_field_id)
    |> foreign_key_constraint(:min_field_id)
    |> foreign_key_constraint(:sec_field_id)
  end

  defp put_col_name(changeset) do
    ds = get_field(changeset, :data_set_id)
    yr = get_field(changeset, :yr_field_id)
    mo = get_field(changeset, :mo_field_id)
    day = get_field(changeset, :day_field_id)
    hr = get_field(changeset, :hr_field_id)
    min = get_field(changeset, :min_field_id)
    sec = get_field(changeset, :sec_field_id)

    do_put_col_name(changeset, ds, yr, mo, day, hr, min, sec)
  end

  defp do_put_col_name(changeset, ds, yr, nil, nil, nil, nil, nil) when not is_nil(yr),
    do: put_change(changeset, :col_name, postgresify("vd #{ds} #{yr}"))

  defp do_put_col_name(changeset, ds, yr, mo, nil, nil, nil, nil) when not is_nil(yr) and not is_nil(mo),
    do: put_change(changeset, :col_name, postgresify("vd #{ds} #{yr} #{mo}"))

  defp do_put_col_name(changeset, ds, yr, mo, day, nil, nil, nil) when not is_nil(yr) and not is_nil(mo) and not is_nil(day),
    do: put_change(changeset, :col_name, postgresify("vd #{ds} #{yr} #{mo} #{day}"))

  defp do_put_col_name(changeset, ds, yr, mo, day, hr, nil, nil) when not is_nil(yr) and not is_nil(mo) and not is_nil(day) and not is_nil(hr),
    do: put_change(changeset, :col_name, postgresify("vd #{ds} #{yr} #{mo} #{day} #{hr}"))

  defp do_put_col_name(changeset, ds, yr, mo, day, hr, min, nil) when not is_nil(yr) and not is_nil(mo) and not is_nil(day) and not is_nil(hr) and not is_nil(min),
    do: put_change(changeset, :col_name, postgresify("vd #{ds} #{yr} #{mo} #{day} #{hr} #{min}"))

  defp do_put_col_name(changeset, ds, yr, mo, day, hr, min, sec) when not is_nil(yr) and not is_nil(mo) and not is_nil(day) and not is_nil(hr) and not is_nil(min) and not is_nil(sec),
    do: put_change(changeset, :col_name, postgresify("vd #{ds} #{yr} #{mo} #{day} #{hr} #{min} #{sec}"))

  defp do_put_col_name(changeset, _, _, _, _, _, _, _), do: changeset
end
