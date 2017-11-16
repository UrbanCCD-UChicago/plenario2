defmodule Plenario2.Core.Actions.VirtualDateFieldActions do
  import Ecto.Query
  alias Plenario2.Core.Changesets.VirtualDateFieldChangesets
  alias Plenario2.Core.Schemas.VirtualDateField
  alias Plenario2.Repo

  def create(meta_id, year, month \\ nil, day \\ nil, hour \\ nil, minute \\ nil, second \\ nil) do
    params = %{
      meta_id: meta_id,
      year_field: year,
      month_field: month,
      day_field: day,
      hour_field: hour,
      minute_field: minute,
      second_field: second
    }

    VirtualDateFieldChangesets.create(%VirtualDateField{}, params)
    |> Repo.insert()
  end

  def list_for_meta(meta), do: Repo.all(from f in VirtualDateField, where: f.meta_id == ^meta.id)

  def delete(field), do: Repo.delete(field)
end
