defmodule Plenario2.Actions.VirtualPointFieldActions do
  @moduledoc """
  This module provides a common API for the business logic
  underlying the various public interfaces for VirtualDateField.
  """

  import Ecto.Query

  alias Plenario2.Changesets.VirtualPointFieldChangesets
  alias Plenario2.Schemas.{VirtualPointField, Meta}
  alias Plenario2.Repo

  @doc """
  Create a new VirtualPointField from a long/lat pair
  """
  @spec create_from_long_lat(meta_id :: integer, longitude :: String.t, latitude :: String.t) :: {:ok, %VirtualPointField{} | :error, Ecto.Changeset.t}
  def create_from_long_lat(meta_id, longitude, latitude) do
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
  @spec create_from_loc(meta_id :: integer, location :: String.t) :: {:ok, %VirtualPointField{} | :error, Ecto.Changeset.t}
  def create_from_loc(meta_id, location) do
    params = %{meta_id: meta_id, location_field: location}

    VirtualPointFieldChangesets.create_from_loc(%VirtualPointField{}, params)
    |> Repo.insert()
  end

  @doc """
  Lists all VirtualPointFields for a given Meta
  """
  @spec list_for_meta(meta :: %Meta{}) :: [%VirtualPointField{}]
  def list_for_meta(meta), do: Repo.all(from f in VirtualPointField, where: f.meta_id == ^meta.id)

  @doc """
  Deletes a given VirtualPointField
  """
  @spec delete(field :: %VirtualPointField{}) :: {:ok, %VirtualPointField{} | :error, Ecto.Changeset.t}
  def delete(field), do: Repo.delete(field)
end
