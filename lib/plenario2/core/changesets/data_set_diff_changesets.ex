defmodule Plenario2.Core.Changesets.DataSetDiffChangeset do
  import Ecto.Changeset

  def create(struct, params) do
    struct
    |> cast(params, [
         :column,
         :original,
         :updated,
         :changed_on,
         :meta_id,
         :datasetconstraint_id,
         :etljob_id
       ])
    |> validate_required([
         :column,
         :original,
         :updated,
         :changed_on,
         :meta_id,
         :datasetconstraint_id,
         :etljob_id
       ])
    |> cast_assoc(:meta)
    |> cast_assoc(:data_set_constraint)
    |> cast_assoc(:etl_job)
  end
end
