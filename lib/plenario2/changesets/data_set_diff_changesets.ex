defmodule Plenario2.Changesets.DataSetDiffChangesets do
  @moduledoc """
  This module provides functions for creating changesets for
  DataSetDiff structs.
  """

  import Ecto.Changeset

  alias Plenario2.Schemas.DataSetDiff

  @doc """
  Creates a changeset for inserting a new DataSetDiff into the database

  Params include:

    - column
    - original
    - update
    - changed_on
    - constraint_values (map of field names as keys and the row values as values)
    - meta_id
    - data_set_constraint_id
    - etl_job_id
  """
  @spec create(struct :: %DataSetDiff{}, params :: %{}) :: Ecto.Changeset.t
  def create(struct, params) do
    struct
    |> cast(params, [
         :column,
         :original,
         :update,
         :changed_on,
         :constraint_values,
         :meta_id,
         :data_set_constraint_id,
         :etl_job_id
       ])
    |> validate_required([
         :column,
         :original,
         :update,
         :changed_on,
         :constraint_values,
         :meta_id,
         :data_set_constraint_id,
         :etl_job_id
       ])
    |> cast_assoc(:meta)
    |> cast_assoc(:data_set_constraint)
    |> cast_assoc(:etl_job)
  end
end
