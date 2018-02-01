defmodule PlenarioEtl.Actions.DataSetDiffActions do
  @moduledoc """
  This module provides a common API for the business logic
  underlying the various public interfaces for DataSetDiff.
  """

  import Ecto.Query

  alias PlenarioEtl.Changesets.DataSetDiffChangesets
  alias PlenarioEtl.Schemas.DataSetDiff

  alias Plenario.Schemas.Meta
  alias Plenario.Repo

  require Logger

  @typedoc """
  Returns a tuple of :ok, DataSetDiff or :error, Ecto.Changeset
  """
  @type ok_diff :: {:ok, DataSetDiff} | {:error, Ecto.Changeset.T}

  @doc """
  Creates a new instance of DataSetDiff.
  """
  @spec create(meta_id :: integer, constraint_id :: integer, etl_job_id :: integer, column :: String.t(), original :: any, updated :: any, changed_on :: DateTime, constraint_values :: map) :: ok_diff
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

    Logger.info("Creating DataSetDiff: #{inspect(params)}")

    DataSetDiffChangesets.create(params)
    |> Repo.insert()
  end

  @doc """
  Lists all entries for DataSetDiff in the database, optionally filtered
  to only include results whose Meta relationship matches the `meta` param.

  ## Examples

    all_diffs = DataSetDiffActions.list()
    my_metas_diffs = DataSetDiffActions.list(meta)
  """
  @spec list(meta :: Meta | integer | nil) :: list(DataSetDiff)
  def list(), do: list(nil)
  def list(meta) when not is_integer(meta) and not is_nil(meta), do: list(meta.id)
  def list(meta) when is_integer(meta) or is_nil(meta) do
    query =
      case is_nil(meta) do
        true -> from(d in DataSetDiff)
        false -> from(d in DataSetDiff, where: d.meta_id == ^meta)
      end

    Repo.all(query)
  end
end
