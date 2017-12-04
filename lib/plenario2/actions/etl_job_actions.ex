defmodule Plenario2.Actions.EtlJobActions do
  import Ecto.Query
  alias Plenario2.Changesets.EtlJobChangesets
  alias Plenario2.Schemas.EtlJob
  alias Plenario2.Repo

  def create(meta_id) do
    EtlJobChangesets.create(%EtlJob{}, %{meta_id: meta_id})
    |> Repo.insert()
  end

  def get_from_id(id), do: Repo.get_by(EtlJob, id: id)

  def list(), do: Repo.all(EtlJob)

  def list_for_meta(meta), do: Repo.all(from job in EtlJob, where: job.meta_id == ^meta.id)

  def mark_started(job) do
    EtlJobChangesets.mark_started(job)
    |> Repo.update()
  end

  def mark_erred(job, error_message) do
    EtlJobChangesets.mark_erred(job, %{error_message: error_message})
    |> Repo.update()
  end

  def mark_completed(job) do
    EtlJobChangesets.mark_completed(job)
    |> Repo.update()
  end
end
