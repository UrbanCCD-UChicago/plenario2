defmodule Plenario2.Actions.DataSetFieldActions do
  @moduledoc """
  This module provides a common API for the business logic
  underlying the various public interfaces for DataSetField.
  """

  import Ecto.Query

  alias Plenario2.Changesets.DataSetFieldChangesets
  alias Plenario2.Schemas.{DataSetField, Meta}
  alias Plenario2.Repo

  @doc """
  Crates a new instance of DataSetField
  """
  @spec create(meta_id :: integer, name :: String.t, type :: String.t, opts :: String.t) :: {:ok, %DataSetField{} | :error, Ecto.Changeset.t}
  def create(meta_id, name, type, opts \\ "default null") do
    params = %{
      meta_id: meta_id,
      name: name,
      type: type,
      opts: opts
    }

    DataSetFieldChangesets.create(%DataSetField{}, params)
    |> Repo.insert()
  end

  @doc """
  Gets a list of fields related to a given Meta
  """
  @spec list_for_meta(meta :: %Meta{}) :: [%DataSetField{}]
  def list_for_meta(meta), do: Repo.all(from f in DataSetField, where: f.meta_id == ^meta.id)

  def make_primary_key(field) do
    DataSetFieldChangesets.make_primary_key(field)
    |> Repo.update()
  end

  @doc """
  Deletes a given data set field
  """
  @spec delete(field :: %DataSetField{}) :: {:ok, %DataSetField{} | :error, Ecto.Changeset.t}
  def delete(field), do: Repo.delete(field)
end
