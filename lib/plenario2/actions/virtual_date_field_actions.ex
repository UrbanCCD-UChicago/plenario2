defmodule Plenario2.Actions.VirtualDateFieldActions do
  @moduledoc """
  This module provides a common API for the business logic
  underlying the various public interfaces for VirtualDateField.
  """

  import Ecto.Query

  import Plenario2.Guards, only: [is_id: 1]

  alias Plenario2.Changesets.VirtualDateFieldChangesets
  alias Plenario2.Schemas.{VirtualDateField, Meta}
  alias Plenario2.Repo

  @typedoc """
  Parameter is an ID attribute
  """
  @type id :: String.t | integer

  @typedoc """
  Returns a tuple of :ok, VirtualDateField or :error, Ecto.Changeset
  """
  @type ok_field :: {:ok, VirtualDateField} | {:error, Ecto.Changeset.T}

  @doc """
  Creates a new instance of a VirtualDateField
  """
  @spec create(meta :: Meta | id, year :: String.t, month :: String.t | nil, day :: String.t | nil, hour :: String.t | nil, minute :: String.t | nil, second :: String.t | nil) :: ok_field
  def create(meta, year, month \\ nil, day \\ nil, hour \\ nil, minute \\ nil, second \\ nil) do
    meta_id =
      case is_id(meta) do
        true -> meta
        false -> meta.id
      end

    params = %{
      meta_id: meta_id,
      year_field: year,
      month_field: month,
      day_field: day,
      hour_field: hour,
      minute_field: minute,
      second_field: second
    }

    VirtualDateFieldChangesets.create(params)
    |> Repo.insert()
  end

  @doc """
  Gets a list of all VirtualDateFields for given Meta
  """
  @spec list_for_meta(meta :: Meta | id) :: list(VirtualDateField)
  def list_for_meta(meta) do
    meta_id =
      case is_id(meta) do
        true -> meta
        false -> meta.id
      end

    Repo.all(
      from f in VirtualDateField,
      where: f.meta_id == ^meta_id
    )
  end

  @doc """
  Gets a VirtualDateField by id
  """
  @spec get(id :: id) :: VirtualDateField | nil
  def get(id) do
    Repo.one(
      from f in VirtualDateField,
      where: f.id == ^id
    )
  end

  @doc """
  Updates a VirtualDateField
  """
  @spec update(field :: VirtualDateField, params :: map) :: VirtualDateField
  def update(field, params \\ %{}) do
    VirtualDateFieldChangesets.update(field, params)
    |> Repo.update()
  end

  @doc """
  Deletes a given VirtualDateField
  """
  @spec delete(field :: %VirtualDateField{}) :: {:ok, %VirtualDateField{} | :error, Ecto.Changeset.t}
  def delete(field), do: Repo.delete(field)
end
