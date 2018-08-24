defmodule Plenario do
  @moduledoc """
  The main, high level interface for working with Plenario data. Mostly, this
  will surface data sets via searches.
  """

  import Ecto.Query

  import Geo.PostGIS, only: [st_intersects: 2]

  import Plenario.Queries.Utils, only: [tsrange_intersects: 2]

  alias Plenario.Repo

  alias Plenario.Schemas.Meta

  @doc """
  Searches Metas whose bounding box intersects with the bounding box
  param, and optionally whose time range intersects with the time range param.
  """
  @spec search_data_sets(user_geom :: Geo.Polygon, time_range :: Postgrex.Range | nil) :: list(Meta)
  def search_data_sets(user_geom, user_time_range \\ nil) do
    search_bbox(user_geom, user_time_range)
    |> Repo.all()
    |> refine_to_hull(user_geom)
    |> Repo.all()
  end

  defp search_bbox(user_geom, user_time_range) do
    Meta
    |> where([m], m.state == ^"ready")
    |> select([m], m.id)
    |> do_search_bbox(user_geom, user_time_range)
  end

  defp do_search_bbox(query, user_geom, nil) do
    query
    |> where([m], st_intersects(m.bbox, ^user_geom))
  end

  defp do_search_bbox(query, user_geom, user_time_range) do
    user_time_range = Plenario.TsRange.to_postgrex(user_time_range)

    do_search_bbox(query, user_geom, nil)
    |> where([m], tsrange_intersects(m.time_range, ^user_time_range))
  end

  defp refine_to_hull(ids, user_geom) do
    Meta
    |> where([m], m.id in ^ids)
    |> where([m], st_intersects(m.hull, ^user_geom))
    |> preload(charts: :meta, user: :metas)
  end
end
