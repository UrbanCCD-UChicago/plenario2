defmodule Plenario2.Actions.VirtualPointFieldActions do
  @moduledoc """
  This module provides a common API for the business logic
  underlying the various public interfaces for VirtualDateField.
  """

  import Ecto.Query

  import Plenario2.Guards, only: [is_id: 1]

  alias Plenario2.Changesets.VirtualPointFieldChangesets
  alias Plenario2.Schemas.{VirtualPointField, Meta}
  alias Plenario2.Repo

  @typedoc """
  Parameter is an ID attribute
  """
  @type id :: String.t | integer

  @typedoc """
  Returns a tuple of :ok, VirtualPointField or :error, Ecto.Changeset
  """
  @type ok_field :: {:ok, VirtualPointField} | {:error, Ecto.Changeset.T}

  @doc """
  Create a new VirtualPointField from a long/lat pair
  """
  @spec create_from_long_lat(meta :: Meta | id, longitude :: String.t, latitude :: String.t) :: ok_field
  def create_from_long_lat(meta, longitude, latitude) do
    meta_id =
      case is_id(meta) do
        true -> meta
        false -> meta.id
      end

    params = %{
      meta_id: meta_id,
      longitude_field: longitude,
      latitude_field: latitude
    }

    VirtualPointFieldChangesets.create_from_long_lat(%VirtualPointField{}, params)
    |> Repo.insert()
  end

  @doc """
  Create a new VirtualPointField from a single location text field
  """
  @spec create_from_loc(meta :: Meta | id, location :: String.t) :: ok_field
  def create_from_loc(meta, location) do
    meta_id =
      case is_id(meta) do
        true -> meta
        false -> meta.id
      end

    params = %{meta_id: meta_id, location_field: location}

    VirtualPointFieldChangesets.create_from_loc(%VirtualPointField{}, params)
    |> Repo.insert()
  end

  @doc """
  Lists all VirtualPointFields for a given Meta
  """
  @spec list_for_meta(meta :: Meta | id) :: list(VirtualPointField)
  def list_for_meta(meta) do
    meta_id =
      case is_id(meta) do
        true -> meta
        false -> meta.id
      end

    Repo.all(
      from f in VirtualPointField,
      where: f.meta_id == ^meta_id
    )
  end

  @doc """
  Deletes a given VirtualPointField
  """
  @spec delete(field :: %VirtualPointField{}) :: {:ok, %VirtualPointField{} | :error, Ecto.Changeset.t}
  def delete(field), do: Repo.delete(field)
end
