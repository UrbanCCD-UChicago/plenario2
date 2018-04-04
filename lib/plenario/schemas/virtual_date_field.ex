defmodule Plenario.Schemas.VirtualDateField do
  @moduledoc """
  Defines the schema for VirtalDateField
  """

  use Ecto.Schema

  alias Plenario.Actions.DataSetFieldActions

  alias Plenario.Schemas.VirtualDateField

  @derive {Poison.Encoder, only: [:id, :name, :year_field_id, :month_field_id,
    :day_field_id, :hour_field_id, :minute_field_id, :second_field_id, :meta_id]}
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

  def get_field_choices(nil), do: [{}]
  def get_field_choices(%VirtualDateField{meta_id: meta_id}), do: get_field_choices(meta_id)
  def get_field_choices(meta_id) do
    fields = DataSetFieldActions.list(for_meta: meta_id)
    choices =
      for f <- fields do
        {f.name, f.id}
      end

    [{"Not Used", nil}] ++ choices
  end
end
