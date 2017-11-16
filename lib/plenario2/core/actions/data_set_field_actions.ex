defmodule Plenario2.Core.Actions.DataSetFieldActions do
  import Ecto.Query
  alias Plenario2.Core.Changesets.DataSetFieldChangesets
  alias Plenario2.Core.Schemas.DataSetField
  alias Plenario2.Repo

  def create(meta_id, name, type, opts \\ "default null") do
    params = %{
      meta_id: meta_id,
      name: name,
      type: type,
      opts: opts
    }

    DataSetFieldChangesets.create(%DataSetField{}, params)
    |> Repo.insert()
  end

  def list_for_meta(meta), do: Repo.all(from f in DataSetField, where: f.meta_id == ^meta.id)

  def make_primary_key(field) do
    DataSetFieldChangesets.make_primary_key(field)
    |> Repo.update()
  end

  def delete(field), do: Repo.delete(field)
end
