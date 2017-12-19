defmodule Plenario2.Actions.VirtualDateFieldActions do
  @moduledoc """
  This module provides a common API for the business logic
  underlying the various public interfaces for VirtualDateField.
  """

  import Ecto.Query

  alias Plenario2.Changesets.VirtualDateFieldChangesets
  alias Plenario2.Schemas.{VirtualDateField, Meta}
  alias Plenario2.Repo

  @doc """
  Creates a new instance of a VirtualDateField
  """
  @spec create(meta_id :: integer, year :: String.t, month :: String.t | nil, day :: String.t | nil, hour :: String.t | nil, minute :: String.t | nil, second :: String.t | nil) :: {:ok, %VirtualDateField{} | :error, Ecto.Changeset.t}
  def create(meta_id, year, month \\ nil, day \\ nil, hour \\ nil, minute \\ nil, second \\ nil) do
    params = %{
      meta_id: meta_id,
      year_field: year,
      month_field: month,
      day_field: day,
      hour_field: hour,
      minute_field: minute,
      second_field: second
    }

    VirtualDateFieldChangesets.create(%VirtualDateField{}, params)
    |> Repo.insert()
  end

  @doc """
  Gets a list of all VirtualDateFields for given Meta
  """
  @spec list_for_meta(meta :: %Meta{}) :: [%VirtualDateField{}]
  def list_for_meta(meta), do: Repo.all(from f in VirtualDateField, where: f.meta_id == ^meta.id)

  @doc """
  Deletes a given VirtualDateField
  """
  @spec delete(field :: %VirtualDateField{}) :: {:ok, %VirtualDateField{} | :error, Ecto.Changeset.t}
  def delete(field), do: Repo.delete(field)
end
