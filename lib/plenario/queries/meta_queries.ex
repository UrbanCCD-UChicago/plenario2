defmodule Plenario.Queries.MetaQueries do
  @moduledoc """
  This module provides a stable API for composing Ecto Queries using the Meta
  schema. Functions included in this module can be used as-is or in pipes to
  compose/filter basic queries.

  This module also provides a :handle_opts function to streamline the
  application of composable queries. This is useful in higher level APIs where
  basic queries, such as :list, can also be filtered based on other parameters.
  """

  import Ecto.Query

  import Geo.PostGIS, only: [st_intersects: 2]

  import Plenario.Queries.Utils, only: [tstzrange_intersects: 2]

  alias Plenario.Queries.{Utils, MetaQueries}

  alias Plenario.Schemas.{Meta, User}

  @doc """
  Creates an Ecto Query to list all the Metas in the database.

  ## Example

    all_metas =
      MetaQueries.list()
      |> Repo.all()
  """
  @spec list() :: Ecto.Query.t()
  def list(), do: (from m in Meta)

  @doc """
  Creates an Ecto Query to get a single Meta from the database by either
  its id or slug field.

  ## Examples

    meta =
      MetaQueries.get(123)
      |> Repo.one()

    meta =
      MetaQueries.get("this-is-a-slug")
      |> Repo.one()
  """
  @spec get(id :: integer | String.t()) :: Ecto.Query.t()
  def get(identifier) do
    case is_integer(identifier) or Regex.match?(~r/^\d+$/, identifier) do
      true -> from m in Meta, where: m.id == ^identifier
      false -> from m in Meta, where: m.slug == ^identifier
    end
  end

  @doc """
  A composable query that filters a given query to only include results whose
  state field is "new".

  ## Example

    MetaQueries.list()
    |> MetaQueries.new_only()
    |> Repo.all()
  """
  @spec new_only(query :: Ecto.Query.t()) :: Ecto.Query.t()
  def new_only(query), do: from m in query, where: m.state == "new"

  @doc """
  A composable query that filters a given query to only include results whose
  state field is "needs_approval".

  ## Example

    MetaQueries.list()
    |> MetaQueries.needs_approval_only()
    |> Repo.all()
  """
  @spec needs_approval_only(query :: Ecto.Query.t()) :: Ecto.Query.t()
  def needs_approval_only(query), do: from m in query, where: m.state == "needs_approval"

  @doc """
  A composable query that filters a given query to only include results whose
  state field is "awaiting_first_import".

  ## Example

    MetaQueries.list()
    |> MetaQueries.awaiting_first_import_only()
    |> Repo.all()
  """
  @spec awaiting_first_import_only(query :: Ecto.Query.t()) :: Ecto.Query.t()
  def awaiting_first_import_only(query), do: from m in query, where: m.state == "awaiting_first_import"

  @doc """
  A composable query that filters a given query to only include results whose
  state field is "ready".

  ## Example

    MetaQueries.list()
    |> MetaQueries.ready_only()
    |> Repo.all()
  """
  @spec ready_only(query :: Ecto.Query.t()) :: Ecto.Query.t()
  def ready_only(query), do: from m in query, where: m.state == "ready"

  @doc """
  A composable query that filters a given query to only include results whose
  state field is "erred".

  ## Example

    MetaQueries.list()
    |> MetaQueries.erred_only()
    |> Repo.all()
  """
  @spec erred_only(query :: Ecto.Query.t()) :: Ecto.Query.t()
  def erred_only(query), do: from m in query, where: m.state == "erred"

  @doc """
  A composable query that preloads the User related to the returned Metas.
  """
  @spec with_user(query :: Ecto.Query.t()) :: Ecto.Query.t()
  def with_user(query), do: from m in query, preload: [user: :metas]

  @doc """
  A composable query that preloads the DataSetFields related to the returned Metas.
  """
  @spec with_fields(query :: Ecto.Query.t()) :: Ecto.Query.t()
  def with_fields(query), do: from m in query, preload: [fields: :meta]

  @doc """
  A composable query that preloads the VirtualDateFields related to the returned Metas.
  """
  @spec with_virtual_dates(query :: Ecto.Query.t()) :: Ecto.Query.t()
  def with_virtual_dates(query), do: from m in query, preload: [virtual_dates: :meta]

  @doc """
  A composable query that preloads the VirtualPointFields related to the returned Metas.
  """
  @spec with_virtual_points(query :: Ecto.Query.t()) :: Ecto.Query.t()
  def with_virtual_points(query), do: from m in query, preload: [virtual_points: :meta]

  @doc """
  A composable query that filters returned Metas whose relation to User
  is the user passed as the filter value.
  """
  def for_user(query, %User{} = user), do: for_user(query, user.id)
  def for_user(query, user_id), do: from m in query, where: m.user_id == ^user_id

  @doc """
  A composable query that filters returned Metas whose bounding box intersects
  with the bounding box param.
  """
  @spec bbox_intersects(query :: Ecto.Query.t(), user :: User) :: Ecto.Query.t()
  def bbox_intersects(query, bbox), do: from m in query, where: st_intersects(m.bbox, ^bbox)

  @doc """
  A composable query that filters returned Metas whose time range intersects
  with the time range param.
  """
  @spec time_range_intersects(query :: Ecto.Query.t(), user :: User) :: Ecto.Query.t()
  def time_range_intersects(query, time_range), do: from m in query, where: tstzrange_intersects(m.time_range, ^time_range)

  @doc """
  Conditionally applies boolean and filter composable queries to the given
  query.

  ## Params

  | key / function              | default value | default action     |
  | --------------------------- | ------------- | ------------------ |
  | :new_only                   | false         | doesn't apply func |
  | :needs_approval_only        | false         | doesn't apply func |
  | :awaiting_first_import_only | false         | doesn't apply func |
  | :ready_only                 | false         | doesn't apply func |
  | :erred_only                 | false         | doesn't apply func |
  | :with_user                  | false         | doesn't apply func |
  | :with_fields                | false         | doesn't apply func |
  | :with_virtual_dates         | false         | doesn't apply func |
  | :with_virtual_points        | false         | doesn't apply func |
  | :for_user                   | :dont_use_me  | doesn't apply func |
  | :bbox_intersects            | :dont_use_me  | doesn't apply func |
  | :time_range_intersects      | :dont_use_me  | doesn't apply func |

  ## Examples

    new_metas =
      MetaQueries.list()
      |> MetaQueries.handle_opts(new_only: true)

    my_erred_metas =
      MetaQueries.list()
      |> MetaQueries.handle_opts(for_user: me, erred_only: true)
  """
  def handle_opts(query, opts \\ []) do
    defaults = [
      new_only: false,
      needs_approval_only: false,
      awaiting_first_import_only: false,
      ready_only: false,
      erred_only: false,
      with_user: false,
      with_fields: false,
      with_virtual_dates: false,
      with_virtual_points: false,
      for_user: :dont_use_me,
      bbox_intersects: :dont_use_me,
      time_range_intersects: :dont_use_me
    ]

    opts = Keyword.merge(defaults, opts)

    query
    |> Utils.bool_compose(opts[:new_only], MetaQueries, :new_only)
    |> Utils.bool_compose(opts[:needs_approval_only], MetaQueries, :needs_approval_only)
    |> Utils.bool_compose(opts[:awaiting_first_import_only], MetaQueries, :awaiting_first_import_only)
    |> Utils.bool_compose(opts[:ready_only], MetaQueries, :ready_only)
    |> Utils.bool_compose(opts[:erred_only], MetaQueries, :erred_only)
    |> Utils.bool_compose(opts[:with_user], MetaQueries, :with_user)
    |> Utils.bool_compose(opts[:with_fields], MetaQueries, :with_fields)
    |> Utils.bool_compose(opts[:with_virtual_dates], MetaQueries, :with_virtual_dates)
    |> Utils.bool_compose(opts[:with_virtual_points], MetaQueries, :with_virtual_points)
    |> Utils.filter_compose(opts[:for_user], MetaQueries, :for_user)
    |> Utils.filter_compose(opts[:bbox_intersects], MetaQueries, :bbox_intersects)
    |> Utils.filter_compose(opts[:time_range_intersects], MetaQueries, :time_range_intersects)
  end
end
