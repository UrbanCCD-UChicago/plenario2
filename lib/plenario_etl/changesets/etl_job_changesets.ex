defmodule PlenarioEtl.Changesets.EtlJobChangesets do
  @moduledoc """
  This module provides functions for creating changesets for
  EtlJob structs.
  """

  import Ecto.Changeset

  alias PlenarioEtl.Schemas.EtlJob

  @doc """
  Creates a changeset for inserting new EtlJobs into the database
  """
  @spec create(params :: %{meta_id: integer}) :: Ecto.Changeset.t()
  def create(params) do
    %EtlJob{}
    |> cast(params, [:meta_id])
    |> validate_required([:meta_id])
    |> cast_assoc(:meta)
  end

  def mark_started(job) do
    job
    |> EtlJob.mark_started()
    |> set_started_on()
  end

  def mark_completed(job) do
    job
    |> EtlJob.mark_completed()
    |> set_completed_on()
  end

  def mark_erred(job, params) do
    job
    |> EtlJob.mark_erred()
    |> cast(params, [:error_message])
    |> set_completed_on()
  end

  defp set_started_on(changeset) do
    put_change(changeset, :started_on, DateTime.utc_now())
  end

  defp set_completed_on(changeset) do
    put_change(changeset, :completed_on, DateTime.utc_now())
  end
end
