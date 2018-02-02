defmodule Plenario.Changesets.VirtualPointFieldChangesets do
  @moduledoc """
  This module defines functions used to create and update changesets for
  the VirtualPointField schema.
  """

  import Ecto.Changeset

  import Plenario.Changesets.Utils, only: [
    validate_meta_state: 1,
    set_random_name: 2
  ]

  alias Plenario.Schemas.VirtualPointField

  @type create_params :: %{
    meta_id: integer,
    lat_field_id: integer,
    lon_field_id: integer | nil,
    loc_field_id: integer | nil
  }

  @type update_params :: %{
    lat_field_id: integer,
    lon_field_id: integer | nil,
    loc_field_id: integer | nil
  }

  @required_keys [:meta_id]

  @create_keys [:meta_id, :lat_field_id, :lon_field_id, :loc_field_id]

  @update_keys [:lat_field_id, :lon_field_id, :loc_field_id]

  @spec new() :: Ecto.Changeset.t()
  def new(), do: %VirtualPointField{} |> cast(%{}, @create_keys)

  @spec create(params :: create_params) :: Ecto.Changeset
  def create(params) do
    %VirtualPointField{}
    |> cast(params, @create_keys)
    |> validate_required(@required_keys)
    |> validate_lat_long_loc_selections()
    |> cast_assoc(:meta)
    |> validate_meta_state()
    |> cast_assoc(:lat_field)
    |> cast_assoc(:lon_field)
    |> cast_assoc(:loc_field)
    |> set_random_name("vpf")
  end

  @spec update(instance :: VirtualPointField, params :: update_params) :: Ecto.Changeset
  def update(instance, params) do
    instance
    |> cast(params, @update_keys)
    |> validate_required(@required_keys)
    |> validate_lat_long_loc_selections()
    |> validate_meta_state()
    |> cast_assoc(:lat_field)
    |> cast_assoc(:lon_field)
    |> cast_assoc(:loc_field)
  end

  defp validate_lat_long_loc_selections(changeset) do
    lat = get_field(changeset, :lat_field_id)
    lon = get_field(changeset, :lon_field_id)
    loc = get_field(changeset, :loc_field_id)

    case {lat, lon, loc} do
      {_, _, nil} ->
        if lat != lon do
          changeset
        else
          add_error(changeset, :base, "Lat and lon must be different")
        end
      {nil, nil, _} -> changeset
      {_, _, _} -> add_error(changeset, :base, "Cannot set all three fields")
    end
end
end
