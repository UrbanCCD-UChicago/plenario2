defmodule PlenarioEtl.Actions.EtlJobActions do
  @moduledoc """
  This module provides a common API for the business logic
  underlying the various public interfaces for EtlJob.
  """

  import Ecto.Query


  alias PlenarioEtl.Changesets.EtlJobChangesets
  alias PlenarioEtl.Schemas.EtlJob

  alias Plenario.Schemas.Meta

  alias Plenario.Repo

  @typedoc """
  Returns a tuple of :ok, EtlJob or :error, Ecto.Changeset
  """
  @type ok_job :: {:ok, EtlJob} | {:error, Ecto.Changeset.T}

  @doc """
  Creates a new instance of EtlJob
  """
  @spec create(meta :: Meta | integer) :: ok_job
  def create(meta) when not is_integer(meta), do: create(meta.id)
  def create(meta) when is_integer(meta) do
    EtlJobChangesets.create(%{meta_id: meta})
    |> Repo.insert()
  end

  @doc """
  Creates a new instance of EtlJob
  """
  @spec create!(meta :: Meta | integer) :: EtlJob
  def create!(meta) do
    {:ok, job} = create(meta)
    job
  end

  @doc """
  Gets a single EtlJob from a given ID
  """
  @spec get(id :: integer) :: EtlJob
  def get(id), do: Repo.get_by(EtlJob, id: id)

  @doc """
  Lists all entries for EtlJobs in the database, optionally filtered
  to only include results whose Meta relationship matches the `meta` param.

  ## Examples

    all_jobs = EtlJobActions.list()
    my_metas_jobs = EtlJobActions.list(meta)
  """
  @spec list() :: list(EtlJob)
  def list(), do: list(nil)
  def list(meta) when not is_integer(meta) and not is_nil(meta), do: list(meta.id)
  def list(meta) when is_integer(meta) or is_nil(meta) do
    query =
      case is_nil(meta) do
        true -> from(j in EtlJob)
        false -> from(j in EtlJob, where: j.meta_id == ^meta)
      end

    Repo.all(query)
  end

  def mark_started(job) do
    EtlJobChangesets.mark_started(job)
    |> Repo.update()
  end

  def mark_erred(job, params = %{error_message: _}) do
    EtlJobChangesets.mark_erred(job, params)
    |> Repo.update()
  end

  def mark_completed(job) do
    EtlJobChangesets.mark_completed(job)
    |> Repo.update()
  end
end
