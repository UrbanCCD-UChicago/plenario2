defmodule Plenario do
  @moduledoc """
  The main, high level interface for working with Plenario data. Mostly, this
  will surface data sets via searches.
  """

  alias Plenario.Repo

  alias Plenario.Schemas.Meta

  alias Plenario.Queries.MetaQueries

  @doc """
  Searches Metas whose bounding box intersects with the bounding box
  param, and optionally whose time range intersects with the time range param.
  """
  @spec search_data_sets(bbox :: Geo.Polygon, time_range :: Postgrex.Range | nil) :: list(Meta)
  def search_data_sets(bbox, time_range \\ nil) do
    query =
      case time_range == nil do
        true ->
          MetaQueries.list()
          |> MetaQueries.handle_opts(
              with_user: true,
              with_charts: true,
              ready_only: true,
              bbox_intersects: bbox)

        false ->
          range =
            case time_range do
              %Plenario.TsRange{} ->
                {:ok, range} = Plenario.TsRange.dump(time_range)
                range
              %Postgrex.Range{} ->
                time_range
            end
          MetaQueries.list()
          |> MetaQueries.handle_opts(
              with_user: true,
              with_charts: true,
              ready_only: true,
              bbox_intersects: bbox,
              time_range_intersects: range)
      end

    Repo.all(query)
  end
end
