defmodule Plenario2.Core.Schemas.DataSetField do
  use Ecto.Schema

  schema "data_set_fields" do
    field :name,  :string
    field :type,  :string
    field :opts,  :string

    belongs_to :meta, Core.Schemas.Meta
  end
end
