defmodule Plenario2.Actions.DataSetDiffActions do
  @moduledoc """
  This module provides a common API for the business logic
  underlying the various public interfaces for DataSetDiff.
  """

  import Ecto.Query

  alias Plenario2.Changesets.DataSetDiffChangesets
  alias Plenario2.Schemas.{DataSetDiff, Meta}
  alias Plenario2.Repo

  @doc """
  Creates a new instance of DataSetDiff.
  """
  @spec create(meta_id :: integer, constraint_id :: integer, etl_job_id :: integer, column :: String.t, original :: any, updated :: any, changed_on :: %DateTime{}, constraint_values :: %{}) :: {:ok, %DataSetDiff{} | :error, Ecto.Changeset.t}
  def create(meta_id, constraint_id, etl_job_id, column, original, updated, changed_on, constraint_values) do
    params = %{
      meta_id: meta_id,
      data_set_constraint_id: constraint_id,
      etl_job_id: etl_job_id,
      column: column,
      original: original,
      update: updated,
      changed_on: changed_on,
      constraint_values: constraint_values
    }

    DataSetDiffChangesets.create(%DataSetDiff{}, params)
    |> Repo.insert()
  end

  @doc """
  Lists all the diffs related to a given Meta.
  """
  @spec list_for_meta(meta :: %Meta{}) :: [%DataSetDiff{}]
  def list_for_meta(meta), do: Repo.all(from d in DataSetDiff, where: d.meta_id == ^meta.id)
end
