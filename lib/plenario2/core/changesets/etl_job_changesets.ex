defmodule Plenario2.Core.Changesets.EtlJobChangesets do
  import Ecto.Changeset

  def create(struct, params) do
    struct
    |> cast(params, [:meta_id])
    |> validate_required([:meta_id])
    |> cast_assoc(:meta)
    |> put_change(:state, "new")
  end

  def mark_started(job) do
    job
    |> cast(%{}, [])
    |> put_change(:state, "running")
    |> put_change(:started_on, DateTime.utc_now())
  end

  def mark_erred(job, params) do
    job
    |> cast(params, [:error_message])
    |> put_change(:state, "erred")
    |> put_change(:completed_on, DateTime.utc_now())
  end

  def mark_completed(job) do
    job
    |> cast(%{}, [])
    |> put_change(:state, "completed")
    |> put_change(:completed_on, DateTime.utc_now())
  end
end
