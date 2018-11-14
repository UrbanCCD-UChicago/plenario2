defmodule Plenario.VirtualPointQueries do
  import Ecto.Query

  import Plenario.QueryUtils

  alias Plenario.{
    DataSet,
    VirtualPoint,
    VirtualPointQueries
  }

  def list, do: from p in VirtualPoint

  def get(id), do: from p in VirtualPoint, where: p.id == ^id

  def with_data_set(query), do: from p in query, preload: [:data_set]

  def with_fields(query), do: from p in query, preload: [
    loc_field: :virtual_locs,
    lon_field: :virtual_lons,
    lat_field: :virtual_lats
  ]

  def for_data_set(query, %DataSet{id: id}), do: for_data_set(query, id)
  def for_data_set(query, id), do: from p in query, where: p.data_set_id == ^id

  def handle_opts(query, opts \\ []) do
    opts = [
      with_data_set: false,
      with_fields: false,
      for_data_set: :empty
    ]
    |> Keyword.merge(opts)

    query
    |> boolean_compose(opts[:with_data_set], VirtualPointQueries, :with_data_set)
    |> boolean_compose(opts[:with_fields], VirtualPointQueries, :with_fields)
    |> filter_compose(opts[:for_data_set], VirtualPointQueries, :for_data_set)
  end
end
