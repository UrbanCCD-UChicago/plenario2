defmodule Plenario2.Actions.EtlJobActions do
  @moduledoc """
  This module provides a common API for the business logic
  underlying the various public interfaces for EtlJob.
  """

  import Ecto.Changeset
  import Ecto.Query

  import Plenario2.Guards, only: [is_id: 1]

  alias Plenario2.Changesets.EtlJobChangesets
  alias Plenario2.Schemas.{EtlJob, Meta}
  alias Plenario2.Repo

  @typedoc """
  Parameter is an ID attribute
  """
  @type id :: String.t() | integer

  @typedoc """
  Returns a tuple of :ok, EtlJob or :error, Ecto.Changeset
  """
  @type ok_job :: {:ok, EtlJob} | {:error, Ecto.Changeset.T}

  @doc """
  Creates a new instance of EtlJob
  """
  @spec create(meta :: Meta | id) :: ok_job
  def create(meta) do
    meta_id =
      case is_id(meta) do
        true -> meta
        false -> meta.id
      end

    EtlJobChangesets.create(%{meta_id: meta_id})
    |> Repo.insert()
  end

  @doc """
  Creates a new instance of EtlJob
  """
  @spec create!(meta :: Meta | id) :: {:ok, EtlJob}
  def create!(meta) do
    {:ok, job} = create(meta)
    job
  end

  @doc """
  Gets a single EtlJob from a given ID
  """
  @spec get(id :: id) :: EtlJob
  def get(id), do: Repo.get_by(EtlJob, id: id)

  @doc """
  Gets a list of all EtlJobs
  """
  @spec list() :: list(EtlJob)
  def list(), do: Repo.all(EtlJob)

  @doc """
  Gets a list of all EtlJobs related to a given Meta
  """
  @spec list_for_meta(meta :: Meta | id) :: list(EtlJob)
  def list_for_meta(meta) do
    meta_id =
      case is_id(meta) do
        true -> meta
        false -> meta.id
      end

    Repo.all(from(job in EtlJob, where: job.meta_id == ^meta_id))
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
