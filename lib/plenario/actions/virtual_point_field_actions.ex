defmodule Plenario.Actions.VirtualPointFieldActions do
  @moduledoc """
  This module provides a common API for the business logic
  underlying the various public interfaces for VirtualDateField.
  """

  import Ecto.Query

  import Plenario.Guards, only: [is_id: 1]

  alias Plenario.Changesets.VirtualPointFieldChangesets
  alias Plenario.Schemas.{VirtualPointField, Meta}
  alias Plenario.Repo

  require Logger

  @typedoc """
  Parameter is an ID attribute
  """
  @type id :: String.t() | integer

  @typedoc """
  Returns a tuple of :ok, VirtualPointField or :error, Ecto.Changeset
  """
  @type ok_field :: {:ok, VirtualPointField} | {:error, Ecto.Changeset.T}

  @doc """
  Create a new VirtualPointField from a long/lat pair
  """
  @spec create_from_long_lat(meta :: Meta | id, longitude :: String.t(), latitude :: String.t()) ::
          ok_field
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

    Logger.info("Creating VirtualPointField from long/lat: #{inspect(params)}")

    VirtualPointFieldChangesets.create_from_long_lat(params)
    |> Repo.insert()
  end

  @doc """
  Create a new VirtualPointField from a single location text field
  """
  @spec create_from_loc(meta :: Meta | id, location :: String.t()) :: ok_field
  def create_from_loc(meta, location) do
    meta_id =
      case is_id(meta) do
        true -> meta
        false -> meta.id
      end

    params = %{meta_id: meta_id, location_field: location}

    Logger.info("Creating VirtualPointField from text field: #{inspect(params)}")

    VirtualPointFieldChangesets.create_from_loc(params)
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

    Repo.all(from(f in VirtualPointField, where: f.meta_id == ^meta_id))
  end

  @doc """
  Deletes a given VirtualPointField
  """
  @spec delete(field :: %VirtualPointField{}) ::
          {:ok, %VirtualPointField{} | :error, Ecto.Changeset.t()}
  def delete(field) do
    Logger.info("Deleting VirtualPointField: #{inspect(field)}")
    Repo.delete(field)
  end
end
