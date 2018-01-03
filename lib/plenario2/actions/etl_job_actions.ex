defmodule Plenario2.Actions.EtlJobActions do
  @moduledoc """
  This module provides a common API for the business logic
  underlying the various public interfaces for EtlJob.
  """

  import Ecto.Query

  alias Plenario2.Changesets.EtlJobChangesets
  alias Plenario2.Schemas.{EtlJob, Meta}
  alias Plenario2.Repo

  @doc """
  Creates a new instance of EtlJob
  """
  @spec create(meta_id :: integer) :: {:ok, %EtlJob{} | :error, Ecto.Changeset.t}
  def create(meta_id) do
    EtlJobChangesets.create(%EtlJob{}, %{meta_id: meta_id})
    |> Repo.insert()
  end

  @doc """
  Creates a new instance of EtlJob
  """
  @spec create!(meta_id :: integer) :: {:ok, %EtlJob{}}
  def create!(meta_id) do
    {:ok, job} = create(meta_id)
    job
  end

  @doc """
  Gets a single EtlJob from a given ID
  """
  @spec get_from_id(id :: integer) :: %EtlJob{}
  def get_from_id(id), do: Repo.get_by(EtlJob, id: id)

  @doc """
  Gets a list of all EtlJobs
  """
  @spec list() :: [%EtlJob{}]
  def list(), do: Repo.all(EtlJob)

  @doc """
  Gets a list of all EtlJobs related to a given Meta
  """
  @spec list_for_meta(meta :: %Meta{}) :: [%EtlJob{}]
  def list_for_meta(meta), do: Repo.all(from job in EtlJob, where: job.meta_id == ^meta.id)

  # TODO: this should be converted to an FSM function on the schema, a la Meta states
  def mark_started(job) do
    EtlJobChangesets.mark_started(job)
    |> Repo.update()
  end

  # TODO: this should be converted to an FSM function on the schema, a la Meta states
  def mark_erred(job, error_message) do
    EtlJobChangesets.mark_erred(job, %{error_message: error_message})
    |> Repo.update()
  end

  # TODO: this should be converted to an FSM function on the schema, a la Meta states
  def mark_completed(job) do
    EtlJobChangesets.mark_completed(job)
    |> Repo.update()
  end
end
