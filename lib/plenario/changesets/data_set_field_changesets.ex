defmodule Plenario.Changesets.DataSetFieldChangesets do
  @moduledoc """
  This module defines functions used to create and update changesets for
  the DataSetField schema.
  """

  import Ecto.Changeset

  import Plenario.Changesets.Utils, only: [validate_meta_state: 1]

  alias Plenario.Schemas.DataSetField

  @type create_params :: %{
    name: String.t(),
    type: String.t(),
    description: String.t(),
    meta_id: integer
  }

  @type update_params :: %{
    name: String.t(),
    type: String.t(),
    description: String.t()
  }

  @required_keys [:name, :type, :meta_id]

  @create_keys [:name, :description, :type, :meta_id]

  @update_keys [:name, :description, :type]

  @spec new() :: Ecto.Changeset.t()
  def new(), do: %DataSetField{} |> cast(%{}, @create_keys)

  @spec create(params :: create_params) :: Ecto.Changeset.t()
  def create(params) do
    %DataSetField{}
    |> cast(params, @create_keys)
    |> validate_required(@required_keys)
    |> cast_assoc(:meta)
    |> validate_type()
    |> validate_meta_state()
  end

  @spec update(instance :: DataSetField, params :: update_params) :: Ecto.Changeset.t()
  def update(instance, params) do
    instance
    |> cast(params, @update_keys)
    |> validate_required(@required_keys)
    |> validate_type()
    |> validate_meta_state()
  end

  defp validate_type(%Ecto.Changeset{valid?: true, changes: %{type: type}} = changeset) do
    case Enum.member?(DataSetField.get_type_values(), type) do
      true -> changeset
      false -> add_error(changeset, :type, "Not a valid type")
    end
  end
  defp validate_type(changeset), do: changeset
end
