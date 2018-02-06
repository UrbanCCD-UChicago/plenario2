defmodule Plenario.Schemas.UniqueConstraint do
  @moduledoc """
  Defines the schema for UniqueConstraint
  """

  use Ecto.Schema

  alias Plenario.Actions.DataSetFieldActions

  schema "unique_constraints" do
    field :name, :string
    field :field_ids, {:array, :integer}

    timestamps(type: :utc_datetime)

    belongs_to :meta, Plenario.Schemas.Meta
  end

  def get_field_choices(constraint) when is_nil(constraint), do: [{}]
  def get_field_choices(constraint) when not is_nil(constraint) do
    fields = DataSetFieldActions.list(for_meta: constraint.meta_id)
    choices =
      for f <- fields do
        {f.name, f.id}
      end

    choices
  end
end
