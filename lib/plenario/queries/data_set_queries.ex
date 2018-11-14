defmodule Plenario.DataSetQueries do
  import Ecto.Query

  import Geo.PostGIS, only: [
    st_contains: 2,
    st_intersects: 2
  ]

  import Plenario.QueryUtils

  alias Plenario.{
    DataSet,
    DataSetQueries,
    User
  }

  def list, do: from d in DataSet

  def get(id) do
    case Regex.match?(~r/^\d+$/, "#{id}") do
      true -> from d in DataSet, where: d.id == ^id
      false -> from d in DataSet, where: d.slug == ^id
    end
  end

  def with_user(query), do: from d in query, preload: [:user]

  def with_fields(query), do: from d in query, preload: [:fields]

  def with_virtual_dates(query), do: from d in query, preload: [:virtual_dates]

  def with_virtual_points(query), do: from d in query, preload: [:virtual_points]

  def state(query, state), do: from d in query, where: d.state == ^state

  def for_user(query, %User{id: id}), do: for_user(query, id)
  def for_user(query, id), do: from d in query, where: d.user_id == ^id

  def bbox_contains(query, geom), do: from d in query, where: st_contains(d.bbox, ^geom)

  def bbox_intersects(query, geom), do: from d in query, where: st_intersects(d.bbox, ^geom)

  def time_range_contains(query, timestamp), do: from d in query, where: fragment("?::tsrange @> ?::timestamp", d.time_range, ^timestamp)

  def time_range_intersects(query, tsrange), do: from d in query, where: fragment("?::tsrange && ?::tsrange", d.time_range, ^Plenario.TsRange.to_postgrex(tsrange))

  defdelegate order(query, args), to: Plenario.QueryUtils
  defdelegate paginate(query, args), to: Plenario.QueryUtils

  def handle_opts(query, opts \\ []) do
    opts = [
      with_user: false,
      with_fields: false,
      with_virtual_dates: false,
      with_virtual_points: false,
      state: :empty,
      for_user: :empty,
      bbox_contains: :empty,
      bbox_intersects: :empty,
      time_range_contains: :empty,
      time_range_intersects: :empty,
      order: :empty,
      paginate: :empty
    ]
    |> Keyword.merge(opts)

    query
    |> boolean_compose(opts[:with_user], DataSetQueries, :with_user)
    |> boolean_compose(opts[:with_fields], DataSetQueries, :with_fields)
    |> boolean_compose(opts[:with_virtual_dates], DataSetQueries, :with_virtual_dates)
    |> boolean_compose(opts[:with_virtual_points], DataSetQueries, :with_virtual_points)
    |> filter_compose(opts[:state], DataSetQueries, :state)
    |> filter_compose(opts[:for_user], DataSetQueries, :for_user)
    |> filter_compose(opts[:bbox_contains], DataSetQueries, :bbox_contains)
    |> filter_compose(opts[:bbox_intersects], DataSetQueries, :bbox_intersects)
    |> filter_compose(opts[:time_range_contains], DataSetQueries, :time_range_contains)
    |> filter_compose(opts[:time_range_intersects], DataSetQueries, :time_range_intersects)
    |> filter_compose(opts[:order], DataSetQueries, :order)
    |> filter_compose(opts[:paginate], DataSetQueries, :paginate)
  end
end
