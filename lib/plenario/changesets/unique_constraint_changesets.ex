defmodule Plenario.Changesets.UniqueConstraintChangesets do
  @moduledoc """
  This module defines functions used to create Ecto Changesets for various
  states of the UniqueConstraint schema.
  """

  import Ecto.Changeset

  import Plenario.Changesets.Utils, only: [validate_meta_state: 1]

  alias Plenario.Schemas.UniqueConstraint

  @typedoc """
  A verbose map of parameter types for :create/1
  """
  @type create_params :: %{
    meta_id: integer,
    field_ids: list(integer)
  }

  @typedoc """
  A verbose map of parameter types for :update/2
  """
  @type update_params :: %{field_ids: list(integer)}

  @create_param_keys [:meta_id, :field_ids]

  @update_param_keys [:field_ids]

  @doc """
  Generates a changeset for creating a new Constraint. Creating a new
  constraint is only allowed when the related Meta's state is still "new".
  Once it's no longer new, fields cannot be added.

  ## Examples

    empty_changeset_for_form =
      UniqueConstraintChangesets.create(%{})

    result =
      UniqueConstraintChangesets.create(%{some: "stuff"})
      |> Repo.insert()
    case result do
      {:ok, constraint} -> do_something(with: constraint)
      {:error, changeset} -> do_something_else(with: changeset)
    end
  """
  @spec create(params :: create_params) :: Ecto.Changeset.t()
  def create(params) do
    %UniqueConstraint{}
    |> cast(params, @create_param_keys)
    |> validate_required(@create_param_keys)
    |> cast_assoc(:meta)
    |> validate_meta_state()
    |> validate_fields_length()
    |> set_name()
  end

  @doc """
  Generates a changeset for updating a Constraints's fields. Updating
  is restricted to constraints whose Meta's state is still "new". Once it's
  no longer new, the field cannot be changed.

  ## Example

    result =
      UniqueConstraintChangesets.update(cons, %{field_ids: [321]})
      |> Repo.update()
    case result do
      {:ok, cons} -> do_something(with: cons)
      {:error, changeset} -> do_something_else(with: changeset)
    end
  """
  @spec update(field :: DataSetField, params :: update_params) :: Ecto.Changeset.t()
  def update(constraint, params) do
    constraint
    |> cast(params, @update_param_keys)
    |> validate_required(@update_param_keys)
    |> validate_meta_state()
    |> validate_fields_length()
  end

  defp validate_fields_length(%Ecto.Changeset{valid?: true} = changeset) do
    field_ids = get_field(changeset, :field_ids)
    case length(field_ids) >= 1 do
      true -> changeset
      false -> add_error(changeset, :field_ids, "You must select 1 or more fields")
    end
  end
  defp validate_fields_length(changeset), do: changeset

  defp set_name(%Ecto.Changeset{valid?: true} = changeset) do
    number = :rand.uniform(1_000_000)
    put_change(changeset, :name, "uc_#{number}")
  end
  defp set_name(changeset), do: changeset
end
