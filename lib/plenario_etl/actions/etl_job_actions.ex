defmodule PlenarioEtl.Actions.EtlJobActions do
  @moduledoc """
  This module provides a common API for the business logic
  underlying the various public interfaces for EtlJob.
  """

  require Logger

  import Ecto.Query


  alias PlenarioEtl.Changesets.EtlJobChangesets

  alias PlenarioEtl.Schemas.EtlJob

  alias Plenario.Schemas.Meta

  alias Plenario.Actions.MetaActions

  alias Plenario.Repo

  @typedoc """
  Returns a tuple of :ok, EtlJob or :error, Ecto.Changeset
  """
  @type ok_job :: {:ok, EtlJob} | {:error, Ecto.Changeset.T}

  @doc """
  Creates a new instance of EtlJob
  """
  @spec create!(meta :: Meta | integer) :: EtlJob
  def create!(%Meta{} = meta), do: create!(meta.id)
  def create!(meta) do
    {:ok, job} =
      EtlJobChangesets.create(%{meta_id: meta})
      |> Repo.insert()

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

  def start(job) do
    {:ok, started} =
      EtlJobChangesets.mark_started(job)
      |> Repo.update()

    meta = MetaActions.get(job.meta_id)
    {:ok, _} = MetaActions.update_next_import(meta)

    {:ok, started}
  end

  def mark_succeeded(job) do
    {:ok, job} =
      EtlJobChangesets.mark_succeeded(job)
      |> Repo.update()

    update_meta_attrs(job.meta_id)

    {:ok, job}
  end

  def mark_partial_success(job, errors) do
    {:ok, job} =
      EtlJobChangesets.mark_partial_success(job, %{error_message: inspect(errors)})
      |> Repo.update()

    update_meta_attrs(job.meta_id)

    {:ok, job}
  end

  def mark_erred(job, errors) do
    EtlJobChangesets.mark_erred(job, %{error_message: inspect(errors)})
    |> Repo.update()
  end

  defp update_meta_attrs(meta_id) do
    meta = MetaActions.get(meta_id)

    MetaActions.update_latest_import(meta, DateTime.utc_now())

    try do
      {lower, upper} = MetaActions.compute_time_range!(meta)
      MetaActions.update_time_range(meta, lower, upper)
    rescue
      error ->
        Sentry.capture_exception(error, [stacktrace: System.stacktrace()])
        Logger.error("#{inspect(error)}")
    end

    try do
      bbox = MetaActions.compute_bbox!(meta)
      MetaActions.update_bbox(meta, bbox)
    rescue
      error ->
        Sentry.capture_exception(error, [stacktrace: System.stacktrace()])
        Logger.error("#{inspect(error)}")
    end

    :ok
  end
end
