defmodule Plenario.Schemas.VirtualPointField do
  @moduledoc """
  Defines the schema for VirtalPointField
  """

  use Ecto.Schema

  schema "virtual_point_fields" do
    field :name, :string

    timestamps(type: :utc_datetime)

    belongs_to :meta, Plenario.Schemas.Meta
    belongs_to :lat_field, Plenario.Schemas.DataSetField
    belongs_to :lon_field, Plenario.Schemas.DataSetField
    belongs_to :loc_field, Plenario.Schemas.DataSetField
  end
end
