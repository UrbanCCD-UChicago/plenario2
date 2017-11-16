defmodule Plenario2.Core.Actions.DataSetConstraintActions do
  import Ecto.Query
  alias Plenario2.Core.Changesets.DataSetConstraintChangesets
  alias Plenario2.Core.Schemas.DataSetConstraint
  alias Plenario2.Repo

  def create(meta_id, field_names) do
    params = %{
      meta_id: meta_id,
      field_names: field_names
    }

    DataSetConstraintChangesets.create(%DataSetConstraint{}, params)
    |> Repo.insert()
  end

  def list_for_meta(meta), do: Repo.all(from c in DataSetConstraint, where: c.meta_id == ^meta.id)

  def delete(constraint), do: Repo.delete(constraint)
end
