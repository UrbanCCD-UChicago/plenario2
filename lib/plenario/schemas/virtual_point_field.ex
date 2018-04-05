defmodule Plenario.Schemas.VirtualPointField do
  @moduledoc """
  Defines the schema for VirtalPointField
  """

  use Ecto.Schema

  alias Plenario.Actions.DataSetFieldActions

  alias Plenario.Schemas.VirtualPointField

  schema "virtual_point_fields" do
    field :name, :string

    timestamps(type: :utc_datetime)

    belongs_to :meta, Plenario.Schemas.Meta
    belongs_to :lat_field, Plenario.Schemas.DataSetField
    belongs_to :lon_field, Plenario.Schemas.DataSetField
    belongs_to :loc_field, Plenario.Schemas.DataSetField
  end

  def get_field_choices(nil), do: [{}]
  def get_field_choices(%VirtualPointField{meta_id: meta_id}), do: get_field_choices(meta_id)
  def get_field_choices(meta_id) do
    fields = DataSetFieldActions.list(for_meta: meta_id)
    choices =
      for f <- fields do
        {f.name, f.id}
      end

    [{"Not Used", nil}] ++ choices
  end
end
