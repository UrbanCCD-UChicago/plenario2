defmodule Plenario2.Actions.DataSetDiffActions do
  @moduledoc """
  This module provides a common API for the business logic
  underlying the various public interfaces for DataSetDiff.
  """

  import Ecto.Query

  import Plenario2.Guards, only: [is_id: 1]

  alias Plenario2.Changesets.DataSetDiffChangesets
  alias Plenario2.Schemas.{DataSetDiff, Meta, DataSetConstraint, EtlJob}
  alias Plenario2.Repo

  @typedoc """
  Parameter is an ID attribute
  """
  @type id :: String.t | integer

  @typedoc """
  Returns a tuple of :ok, DataSetDiff or :error, Ecto.Changeset
  """
  @type ok_diff :: {:ok, DataSetDiff} | {:error, Ecto.Changeset.T}

  @doc """
  Creates a new instance of DataSetDiff.
  """
  @spec create(meta :: Meta | id, constraint :: DataSetConstraint | id, etl_job :: EtlJob | id, column :: String.t, original :: any, updated :: any, changed_on :: DateTime, constraint_values :: %{}) :: ok_diff
  def create(meta, constraint, etl_job, column, original, updated, changed_on, constraint_values) do
    meta_id =
      case is_id(meta) do
        true -> meta
        false -> meta.id
      end

    constraint_id =
      case is_id(constraint) do
        true -> constraint
        false -> constraint.id
      end

    etl_job_id =
      case is_id(etl_job) do
        true -> etl_job
        false -> etl_job.id
      end

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
  @spec list_for_meta(meta :: Meta | id) :: list(DataSetDiff)
  def list_for_meta(meta) do
    meta_id =
      case is_id(meta) do
        true -> meta
        false -> meta.id
      end

    Repo.all(
      from d in DataSetDiff,
      where: d.meta_id == ^meta_id
    )
  end
end
