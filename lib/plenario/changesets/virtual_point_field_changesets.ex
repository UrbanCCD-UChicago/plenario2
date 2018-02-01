defmodule Plenario.Changesets.VirtualPointFieldChangesets do
  @moduledoc """
  This module defines functions used to create Ecto Changesets for various
  states of the VirtualPointField schema.
  """

  import Ecto.Changeset

  import Plenario.Changesets.Utils, only: [validate_meta_state: 1]

  alias Plenario.Schemas.VirtualPointField

  @typedoc """
  A verbose map of parameter types for :create/1
  """
  @type create_params :: %{
    meta_id: integer,
    lat_field_id: integer,
    lon_field_id: integer,
    loc_field_id: integer
  }

  @typedoc """
  A verbose map of parameter types for :update/2
  """
  @type update_params :: %{
    lat_field_id: integer,
    lon_field_id: integer,
    loc_field_id: integer
  }

  @create_param_keys [:meta_id, :lat_field_id, :lon_field_id, :loc_field_id]

  @update_param_keys [:lat_field_id, :lon_field_id, :loc_field_id]

  @doc """
  Generates a changeset for creating a new Field. Creating a new field is only
  allowed when the related Meta's state is still "new". Once it's no longer
  new, fields cannot be added.

  ## Examples

    empty_changeset_for_form =
      VirtualPointFieldChangesets.create(%{})

    result =
      VirtualPointFieldChangesets.create(%{some: "stuff"})
      |> Repo.insert()
    case result do
      {:ok, field} -> do_something(with: field)
      {:error, changeset} -> do_something_else(with: changeset)
    end
  """
  @spec create(params :: create_params) :: Ecto.Changeset.t()
  def create(params) do
    %VirtualPointField{}
    |> cast(params, @create_param_keys)
    |> validate_lat_long_loc_selections()
    |> cast_assoc(:meta)
    |> cast_assoc(:lat_field)
    |> cast_assoc(:lon_field)
    |> cast_assoc(:loc_field)
    |> validate_meta_state()
    |> set_name()
  end

  @doc """
  Generates a changeset for updating a Field's name and/or type. Updating
  is restricted to fields whose Meta's state is still "new". Once it's
  no longer new, the field cannot be changed.

  ## Example

    result =
      VirtualPointFieldChangesets.update(field, %{loc_field_id: 321})
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
    |> validate_lat_long_loc_selections()
    |> cast_assoc(:lat_field)
    |> cast_assoc(:lon_field)
    |> cast_assoc(:loc_field)
    |> validate_meta_state()
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

  defp set_name(%Ecto.Changeset{valid?: true} = changeset) do
    number = :rand.uniform(1_000_000)
    put_change(changeset, :name, "_meta_point_#{number}")
  end
  defp set_name(changeset), do: changeset
end
