defmodule Plenario.Changesets.UniqueConstraintChangesets do
  @moduledoc """
  This module defines functions used to create and update changesets for
  the UniqueConstraint schema.
  """

  import Ecto.Changeset

  import Plenario.Changesets.Utils, only: [
    validate_meta_state: 1,
    set_random_name: 2
  ]

  alias Plenario.Schemas.UniqueConstraint

  @type create_params :: %{
    name: String.t(),
    field_ids: list(integer),
    meta_id: integer
  }

  @type update_params :: %{
    name: String.t(),
    field_ids: list(integer)
  }

  @required_keys [:field_ids, :meta_id]

  @create_keys [:field_ids, :meta_id]

  @update_keys [:field_ids]

  @spec new() :: Ecto.Changeset.t()
  def new(), do: %UniqueConstraint{} |> cast(%{}, @create_keys)

  @spec create(params :: create_params) :: Ecto.Changeset
  def create(params) do
    %UniqueConstraint{}
    |> cast(params, @create_keys)
    |> validate_required(@required_keys)
    |> cast_assoc(:meta)
    |> validate_meta_state()
    |> validate_fields_length()
    |> set_random_name("uc")
  end

  @spec update(instance :: UniqueConstraint, params :: update_params) :: Ecto.Changeset
  def update(instance, params) do
    instance
    |> cast(params, @update_keys)
    |> validate_required(@required_keys)
    |> validate_meta_state()
    |> validate_fields_length()
  end

  defp validate_fields_length(%Ecto.Changeset{valid?: true, changes: %{field_ids: field_ids}} = changeset) do
    case length(field_ids) >= 1 do
      true -> changeset
      false -> add_error(changeset, :field_ids, "You must select 1 or more fields")
    end
  end
  defp validate_fields_length(changeset), do: changeset
end
