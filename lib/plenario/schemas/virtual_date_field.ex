defmodule Plenario.Schemas.VirtualDateField do
  use Ecto.Schema

  schema "virtual_date_fields" do
    field(:name, :string)
    field(:year_field, :string)
    field(:month_field, :string)
    field(:day_field, :string)
    field(:hour_field, :string)
    field(:minute_field, :string)
    field(:second_field, :string)

    belongs_to(:meta, Plenario.Schemas.Meta)
  end
end
