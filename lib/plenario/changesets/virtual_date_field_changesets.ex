defmodule Plenario.Changesets.VirtualDateFieldChangesets do
  @moduledoc """
  This module defines functions used to create and update changesets for
  the VirtualDateField schema.
  """

  import Ecto.Changeset

  import Plenario.Changesets.Utils, only: [
    validate_meta_state: 1,
    set_random_name: 2
  ]

  alias Plenario.Schemas.VirtualDateField

  @type create_params :: %{
    meta_id: integer,
    year_field_id: integer,
    month_field_id: integer | nil,
    day_field_id: integer | nil,
    hour_field_id: integer | nil,
    minute_field_id: integer | nil,
    second_field_id: integer | nil
  }

  @type update_params :: %{
    year_field_id: integer,
    month_field_id: integer | nil,
    day_field_id: integer | nil,
    hour_field_id: integer | nil,
    minute_field_id: integer | nil,
    second_field_id: integer | nil
  }

  @required_keys [:meta_id, :year_field_id]

  @create_keys [
    :meta_id, :year_field_id, :month_field_id, :day_field_id,
    :hour_field_id, :minute_field_id, :second_field_id
  ]

  @update_keys [
    :year_field_id, :month_field_id, :day_field_id,
    :hour_field_id, :minute_field_id, :second_field_id
  ]

  @spec new() :: Ecto.Changeset.t()
  def new(), do: %VirtualDateField{} |> cast(%{}, @create_keys)

  @spec create(params :: create_params) :: Ecto.Changeset
  def create(params) do
    %VirtualDateField{}
    |> cast(params, @create_keys)
    |> validate_required(@required_keys)
    |> cast_assoc(:meta)
    |> validate_meta_state()
    |> cast_assoc(:year_field)
    |> cast_assoc(:month_field)
    |> cast_assoc(:day_field)
    |> cast_assoc(:hour_field)
    |> cast_assoc(:minute_field)
    |> cast_assoc(:second_field)
    |> set_random_name("vdf")
  end

  @spec update(instance :: VirtualDateField, params :: update_params) :: Ecto.Changeset
  def update(instance, params) do
    instance
    |> cast(params, @update_keys)
    |> validate_required(@required_keys)
    |> validate_meta_state()
    |> cast_assoc(:year_field)
    |> cast_assoc(:month_field)
    |> cast_assoc(:day_field)
    |> cast_assoc(:hour_field)
    |> cast_assoc(:minute_field)
    |> cast_assoc(:second_field)
  end
end
