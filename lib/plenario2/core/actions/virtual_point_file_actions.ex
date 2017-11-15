defmodule Plenario2.Core.Actions.VirtualPointFieldActions do
  import Ecto.Query
  alias Plenario2.Core.Changesets.VirtualPointFieldChangesets
  alias Plenario2.Core.Schemas.VirtualPointField
  alias Plenario2.Repo

  def create_from_long_lat(meta_id, longitude, latitude) do
    params = %{
      meta_id: meta_id,
      longitude_field: longitude,
      latitude_field: latitude
    }

    VirtualPointFieldChangesets.create_long_lat(%VirtualPointField{}, params)
    |> Repo.insert()
  end

  def create_from_loc(meta_id, location) do
    params = %{meta_id: meta_id, location_field: location}

    VirtualPointFieldChangesets.create_from_loc(%VirtualPointField{}, params)
    |> Repo.insert()
  end

  def list_for_meta(meta), do: Repo.all(from f in VirtualPointField, where: f.meta_id == ^meta.id)

  def delete(field), do: Repo.delete(field)
end
