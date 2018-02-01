defmodule Plenario.Schemas.DataSetField do
  use Ecto.Schema

  schema "data_set_fields" do
    field(:name, :string)
    field(:type, :string)
    field(:opts, :string)

    belongs_to(:meta, Plenario.Schemas.Meta)
  end
end
