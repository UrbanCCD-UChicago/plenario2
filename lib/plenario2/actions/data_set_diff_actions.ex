defmodule Plenario2.Actions.DataSetDiffActions do
  import Ecto.Query
  alias Plenario2.Changesets.DataSetDiffChangesets
  alias Plenario2.Schemas.DataSetDiff
  alias Plenario2.Repo

  def create(meta_id, constraint_id, etl_job_id, column, original, updated, changed_on, constraint_values) do
    params = %{
      meta_id: meta_id,
      data_set_constraint_id: constraint_id,
      etl_job_id: etl_job_id,
      column: column,
      original: original,
      update: updated,
      changed_on: changed_on,
      constraint_values: constraint_values
    }

    DataSetDiffChangesets.create(%DataSetDiff{}, params)
    |> Repo.insert()
  end

  def list_for_meta(meta), do: Repo.all(from d in DataSetDiff, where: d.meta_id == ^meta.id)
end
