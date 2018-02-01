defmodule Plenario.Changesets.VirtualDateFieldChangesets do
  @moduledoc """
  This module defines functions used to create Ecto Changesets for various
  states of the VirtualDateField schema.
  """

  import Ecto.Changeset

  import Plenario.Changesets.Utils, only: [validate_meta_state: 1]

  alias Plenario.Schemas.VirtualDateField

  @typedoc """
  A verbose map of parameter types for :create/1
  """
  @type create_params :: %{
    meta_id: integer,
    year_field_id: integer,
    month_field_id: integer,
    day_field_id: integer,
    hour_field_id: integer,
    minute_field_id: integer,
    second_field_id: integer
  }

  @typedoc """
  A verbose map of parameter types for :update/2
  """
  @type update_params :: %{
    year_field_id: integer,
    month_field_id: integer,
    day_field_id: integer,
    hour_field_id: integer,
    minute_field_id: integer,
    second_field_id: integer
  }

  @create_param_keys [
    :meta_id, :year_field_id, :month_field_id, :day_field_id,
    :hour_field_id, :minute_field_id, :second_field_id
  ]

  @update_param_keys [
    :year_field_id, :month_field_id, :day_field_id,
    :hour_field_id, :minute_field_id, :second_field_id
  ]

  @doc """
  Generates a changeset for creating a new Field. Creating a new field is only
  allowed when the related Meta's state is still "new". Once it's no longer
  new, fields cannot be added.

  ## Examples

    empty_changeset_for_form =
      VirtualDateFieldChangesets.create(%{})

    result =
      VirtualDateFieldChangesets.create(%{some: "stuff"})
      |> Repo.insert()
    case result do
      {:ok, field} -> do_something(with: field)
      {:error, changeset} -> do_something_else(with: changeset)
    end
  """
  @spec create(params :: create_params) :: Ecto.Changeset.t()
  def create(params) do
    %VirtualDateField{}
    |> cast(params, @create_param_keys)
    |> validate_required([:meta_id, :year_field_id])
    |> cast_assoc(:meta)
    |> cast_assoc(:year_field)
    |> cast_assoc(:month_field)
    |> cast_assoc(:day_field)
    |> cast_assoc(:hour_field)
    |> cast_assoc(:minute_field)
    |> cast_assoc(:second_field)
    |> validate_meta_state()
    |> set_name()
  end

  @doc """
  Generates a changeset for updating a Field's name and/or type. Updating
  is restricted to fields whose Meta's state is still "new". Once it's
  no longer new, the field cannot be changed.

  ## Example

    result =
      VirtualDateFieldChangesets.update(field, %{year_field_id: 321})
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
    |> validate_required([:year_field_id])
    |> cast_assoc(:year_field)
    |> cast_assoc(:month_field)
    |> cast_assoc(:day_field)
    |> cast_assoc(:hour_field)
    |> cast_assoc(:minute_field)
    |> cast_assoc(:second_field)
    |> validate_meta_state()
  end

  defp set_name(%Ecto.Changeset{valid?: true} = changeset) do
    number = :rand.uniform(1_000_000)
    put_change(changeset, :name, "_meta_date_#{number}")
  end
  defp set_name(changeset), do: changeset
end
