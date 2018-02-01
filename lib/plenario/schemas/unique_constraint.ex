defmodule Plenario.Schemas.UniqueConstraint do
  @moduledoc """
  Defines the schema for UniqueConstraint
  """

  use Ecto.Schema

  schema "unique_constraints" do
    field :name, :string
    field :field_ids, {:array, :integer}

    timestamps(type: :utc_datetime)

    belongs_to :meta, Plenario.Schemas.Meta
  end
end
