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
  @spec create(params :: %{meta_id: integer}) :: Ecto.Changeset.t()
  def create(params) do
    %EtlJob{}
    |> cast(params, [:meta_id])
    |> validate_required([:meta_id])
    |> cast_assoc(:meta)
    |> put_change(:state, "new")
  end
end
