defmodule Plenario2.Schemas.DataSetField do
  use Ecto.Schema

  schema "data_set_fields" do
    field(:name, :string)
    field(:type, :string)
    field(:opts, :string)

    belongs_to(:meta, Plenario2.Schemas.Meta)
  end
end
