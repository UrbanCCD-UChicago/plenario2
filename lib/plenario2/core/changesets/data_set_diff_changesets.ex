defmodule Plenario2.Core.Changesets.DataSetDiffChangesets do
  import Ecto.Changeset

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
