defmodule Plenario2.Core.Schemas.VirtualPointField do
  use Ecto.Schema

  schema "virtual_point_fields" do
    field(:name, :string)
    field(:longitude_field, :string)
    field(:latitude_field, :string)
    field(:location_field, :string)

    belongs_to(:meta, Plenario2.Core.Schemas.Meta)
  end
end
