defmodule Plenario.Schemas.UniqueConstraint do
  @moduledoc """
  Defines the schema for UniqueConstraint
  """

  use Ecto.Schema

  alias Plenario.Actions.DataSetFieldActions

  alias Plenario.Schemas.UniqueConstraint

  schema "unique_constraints" do
    field :name, :string
    field :field_ids, {:array, :integer}

    timestamps(type: :utc_datetime)

    belongs_to :meta, Plenario.Schemas.Meta
  end

  def get_field_choices(nil = param), do: [{}]
  def get_field_choices(%UniqueConstraint{meta_id: meta_id}), do: get_field_choices(meta_id)
  def get_field_choices(meta_id) do
    fields = DataSetFieldActions.list(for_meta: meta_id)
    choices =
      for f <- fields do
        {f.name, f.id}
      end

    choices
  end
end
