defmodule Plenario2.Changesets.DataSetDiffChangesets do
  @moduledoc """
  This module provides functions for creating changesets for
  DataSetDiff structs.
  """

  import Ecto.Changeset

  alias Plenario2.Schemas.DataSetDiff

  @typedoc """
  Verbose map of params for create
  """
  @type create_params :: %{
    column: String.t,
    original: any,
    update: any,
    changed_on: DateTime,
    constraint_values: list({String.t, any}),
    meta_id: integer,
    data_set_constraint_id: integer,
    etl_job_id: integer
  }

  @param_keys [
    :column, :original, :update, :changed_on, :constraint_values,
    :meta_id, :data_set_constraint_id, :etl_job_id
  ]

  @doc """
  Creates a changeset for inserting a new DataSetDiff into the database
  """
  @spec create(params :: create_params) :: Ecto.Changeset.t
  def create(params) do
    %DataSetDiff{}
    |> cast(params, @param_keys)
    |> validate_required(@param_keys)
    |> cast_assoc(:meta)
    |> cast_assoc(:data_set_constraint)
    |> cast_assoc(:etl_job)
  end
end
