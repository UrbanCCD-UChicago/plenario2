defmodule Plenario.VirtualDateQueries do
  import Ecto.Query

  import Plenario.QueryUtils

  alias Plenario.{
    DataSet,
    VirtualDate,
    VirtualDateQueries
  }

  def list, do: from d in VirtualDate

  def get(id), do: from d in VirtualDate, where: d.id == ^id

  def with_data_set(query), do: from d in query, preload: [:data_set]

  def with_fields(query), do: from d in query, preload: [
    yr_field: :virtual_yrs,
    mo_field: :virtual_mos,
    day_field: :virtual_days,
    hr_field: :virtual_hrs,
    min_field: :virtual_mins,
    sec_field: :virtual_secs
  ]

  def for_data_set(query, %DataSet{id: id}), do: for_data_set(query, id)
  def for_data_set(query, id), do: from d in query, where: d.data_set_id == ^id

  def handle_opts(query, opts \\ []) do
    opts = [
      with_data_set: false,
      with_fields: false,
      for_data_set: :empty
    ]
    |> Keyword.merge(opts)

    query
    |> boolean_compose(opts[:with_data_set], VirtualDateQueries, :with_data_set)
    |> boolean_compose(opts[:with_fields], VirtualDateQueries, :with_fields)
    |> filter_compose(opts[:for_data_set], VirtualDateQueries, :for_data_set)
  end
end
