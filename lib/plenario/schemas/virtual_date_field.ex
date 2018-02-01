defmodule Plenario.Schemas.VirtualDateField do
  @moduledoc """
  Defines the schema for VirtalDateField
  """

  use Ecto.Schema

  schema "virtual_date_fields" do
    field :name, :string

    timestamps(type: :utc_datetime)

    belongs_to :meta, Plenario.Schemas.Meta
    belongs_to :year_field, Plenario.Schemas.DataSetField
    belongs_to :month_field, Plenario.Schemas.DataSetField
    belongs_to :day_field, Plenario.Schemas.DataSetField
    belongs_to :hour_field, Plenario.Schemas.DataSetField
    belongs_to :minute_field, Plenario.Schemas.DataSetField
    belongs_to :second_field, Plenario.Schemas.DataSetField
  end
end
