defmodule Plenario.Queries.VirtualDateFieldQueries do
  @moduledoc """
  This module provides a stable API for composing Ecto Queries using the
  VirtualDateField schema. Functions included in this module can be used as-is
  or in pipes to compose/filter basic queries.

  This module also provides a :handle_opts function to streamline the
  application of composable queries. This is useful in higher level APIs where
  basic queries, such as :list, can also be filtered based on other parameters.
  """

  import Ecto.Query

  alias Plenario.Schemas.{VirtualDateField, Meta}

  alias Plenario.Queries.{VirtualDateFieldQueries, Utils}

  @doc """
  Creates an Ecto Query to list all the VirtualDateFields in the database.

  ## Example

    all_fields =
      VirtualDateFieldQueries.list()
      |> Repo.all()
  """
  @spec list() :: Ecto.Query.t()
  def list(), do: (from f in VirtualDateField)

  @doc """
  A composable query that preloads the DataSetFields related to the returned
  VirtualDateFields.
  """
  @spec with_fields(query :: Ecto.Query.t()) :: Ecto.Query.t()
  def with_fields(query) do
    from m in query, preload: [
      year_field: :virtual_years,
      month_field: :virtual_months,
      day_field: :virtual_days,
      hour_field: :virtual_hours,
      minute_field: :virtual_minutes,
      second_field: :virtual_seconds
    ]
  end

  @doc """
  A composable query that filters the returned VirtualDateFields whose relation
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
  | :with_fields   | false         | doesn't apply func |
  | :for_meta      | :dont_use_me  | doesn't apply func |

  ## Example

    fields =
      VirtualDateFieldQueries.list()
      |> DataSetFieldQueries.handle_opts(with_fields: true, for_meta: my_meta)
      |> Repo.all()
  """
  def handle_opts(query, opts \\ []) do
    defaults = [
      with_fields: false,
      for_meta: :dont_use_me
    ]

    opts = Keyword.merge(defaults, opts)

    query
    |> Utils.bool_compose(opts[:with_fields], VirtualDateFieldQueries, :with_fields)
    |> Utils.filter_compose(opts[:for_meta], VirtualDateFieldQueries, :for_meta)
  end
end
