defmodule Plenario.Changesets.DataSetFieldChangesets do
  @moduledoc """
  This module defines functions used to create Ecto Changesets for various
  states of the DataSetField schema.
  """

  import Ecto.Changeset

  import Plenario.Changesets.Utils, only: [validate_meta_state: 1]

  alias Plenario.Schemas.DataSetField

  @typedoc """
  A verbose map of parameter types for :create/1
  """
  @type create_params :: %{
    name: String.t(),
    type: String.t(),
    meta_id: integer
  }

  @typedoc """
  A verbose map of paramaters for :update/2
  """
  @type update_params :: %{
    name: String.t(),
    type: String.t()
  }

  @create_param_keys [:name, :type, :meta_id]

  @update_param_keys [:name, :type]

  @doc """
  Generates a changeset for creating a new Field. Creating a new field is only
  allowed when the related Meta's state is still "new". Once it's no longer
  new, fields cannot be added.

  ## Examples

    empty_changeset_for_form =
      DataSetFieldChangesets.create(%{})

    result =
      DataSetFieldChangesets.create(%{some: "stuff"})
      |> Repo.insert()
    case result do
      {:ok, field} -> do_something(with: field)
      {:error, changeset} -> do_something_else(with: changeset)
    end
  """
  @spec create(params :: create_params) :: Ecto.Changeset.t()
  def create(params) do
    %DataSetField{}
    |> cast(params, @create_param_keys)
    |> validate_required(@create_param_keys)
    |> cast_assoc(:meta)
    |> validate_type()
    |> validate_meta_state()
  end

  @doc """
  Generates a changeset for updating a DataSetField's name and/or type. Updating
  is restricted to fields whose Meta's state is still "new". Once it's
  no longer new, the field cannot be changed.

  ## Example

    result =
      DataSetFieldChangesets.update(field, %{type: "i dunno"})
      |> Repo.update()
    case result do
      {:ok, field} -> do_something(with: field)
      {:error, changeset} -> do_something_else(with: changeset)
    end
  """
  @spec update(field :: DataSetField, params :: update_params) :: Ecto.Changeset.t()
  def update(field, params) do
    field
    |> cast(params, @update_param_keys)
    |> validate_required(@update_param_keys)
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
