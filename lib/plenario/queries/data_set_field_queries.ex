defmodule Plenario.Queries.DataSetFieldQueries do
  @moduledoc """
  This module provides a stable API for composing Ecto Queries using the
  DataSetField schema. Functions included in this module can be used as-is or
  in pipes to compose/filter basic queries.

  This module also provides a :handle_opts function to streamline the
  application of composable queries. This is useful in higher level APIs where
  basic queries, such as :list, can also be filtered based on other parameters.
  """

  import Ecto.Query

  alias Plenario.Schemas.{DataSetField, Meta}

  alias Plenario.Queries.{DataSetFieldQueries, Utils}

  @doc """
  Creates an Ecto Query to list all the DataSetFields in the database.

  ## Example

    all_fields =
      DataSetFieldQueries.list()
      |> Repo.all()
  """
  @spec list() :: Ecto.Query.t()
  def list(), do: (from f in DataSetField)

  @doc """
  A composable query that filters the given query by a list of IDs.
  """
  @spec by_ids(query :: Ecto.Query.t(), ids :: list(integer)) :: Ecto.Query.t()
  def by_ids(query, ids), do: from f in query, where: f.id in ^ids

  @doc """
  A composable query that filters the returned DataSetFields whose relation
  to Meta is the meta passed as the filter value.
  """
  @spec for_meta(query :: Ecto.Query.t(), meta :: Meta) :: Ecto.Query.t()
  def for_meta(query, meta) when not is_integer(meta), do: for_meta(query, meta.id)

  @spec for_meta(query :: Ecto.Query.t(), meta_id :: integer) :: Ecto.Query.t()
  def for_meta(query, meta_id) when is_integer(meta_id), do: from f in query, where: f.meta_id == ^meta_id

  @doc """
  Conditionally applies boolean and filter composable queries to the given
  query.

  ## Params

  | key / function | default value | default action     |
  | -------------- | ------------- | ------------------ |
  | :by_ids        | :dont_use_me  | doesn't apply func |
  | :for_meta      | :dont_use_me  | doesn't apply func |

  ## Example

    fields =
      DataSetFieldQueries.list()
      |> DataSetFieldQueries.by_ids([123, 234, 345])
      |> Repo.all()
  """
  def handle_opts(query, opts \\ []) do
    defaults = [
      by_ids: :dont_use_me,
      for_meta: :dont_use_me
    ]

    opts = Keyword.merge(defaults, opts)

    query
    |> Utils.filter_compose(opts[:by_ids], DataSetFieldQueries, :by_ids)
    |> Utils.filter_compose(opts[:for_meta], DataSetFieldQueries, :for_meta)
  end
end
