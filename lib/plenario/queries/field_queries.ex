defmodule Plenario.FieldQueries do
  import Ecto.Query

  import Plenario.QueryUtils

  alias Plenario.{
    DataSet,
    Field,
    FieldQueries
  }

  def list, do: from f in Field

  def get(id), do: from f in Field, where: f.id == ^id

  def with_data_set(query), do: from f in query, preload: [:data_set]

  def for_data_set(query, %DataSet{id: id}), do: for_data_set(query, id)
  def for_data_set(query, id), do: from f in query, where: f.data_set_id == ^id

  def handle_opts(query, opts \\ []) do
    opts = [
      with_data_set: false,
      for_data_set: :empty
    ]
    |> Keyword.merge(opts)

    query
    |> boolean_compose(opts[:with_data_set], FieldQueries, :with_data_set)
    |> filter_compose(opts[:for_data_set], FieldQueries, :for_data_set)
  end
end
