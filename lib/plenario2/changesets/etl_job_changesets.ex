defmodule Plenario2.Changesets.EtlJobChangesets do
  @moduledoc """
  This module provides functions for creating changesets for
  EtlJob structs.
  """

  import Ecto.Changeset

  alias Plenario2.Schemas.EtlJob

  @doc """
  Creates a changeset for inserting new EtlJobs into the database
  """
  @spec create(params :: %{meta_id: integer}) :: Ecto.Changeset.t
  def create(params) do
    %EtlJob{}
    |> cast(params, [:meta_id])
    |> validate_required([:meta_id])
    |> cast_assoc(:meta)
    |> put_change(:state, "new")
  end

  # TODO: delete this -- this should be an FSM on the schema
  def mark_started(job) do
    job
    |> cast(%{}, [])
    |> put_change(:state, "running")
    |> put_change(:started_on, DateTime.utc_now())
  end

  # TODO: delete this -- this should be an FSM on the schema
  def mark_erred(job, params) do
    job
    |> cast(params, [:error_message])
    |> put_change(:state, "erred")
    |> put_change(:completed_on, DateTime.utc_now())
  end

  # TODO: delete this -- this should be an FSM on the schema
  def mark_completed(job) do
    job
    |> cast(%{}, [])
    |> put_change(:state, "completed")
    |> put_change(:completed_on, DateTime.utc_now())
  end
end
