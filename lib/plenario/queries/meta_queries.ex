defmodule Plenario.Queries.MetaQueries do
  @moduledoc """
  This module provides functions for building and composing Ecto
  queries. This is beneficial for streamlining the way we interact
  with the database from other business logic and web controller
  modules.
  """

  import Ecto.Query

  import Plenario.Queries.Utils

  alias Plenario.Queries.MetaQueries
  alias Plenario.Schemas.Meta

  alias PlenarioAuth.User

  @doc """
  Creates a query for a single meta entity in the database filtered by its ID
  """
  @spec from_id(id :: integer) :: Ecto.Queryset.t()
  def from_id(id), do: from(m in Meta, where: m.id == ^id)

  @doc """
  Creates a query for a single meta entity in the database filtered by its slug
  """
  @spec from_slug(slug :: String.t()) :: Ecto.Queryset.t()
  def from_slug(slug), do: from(m in Meta, where: m.slug == ^slug)

  @doc """
  Creates a query that gets all meta entities in the database. This can be combined
  with other filters and preloads.

  ## Examples

    iex> new_metas = MetaQueries.list() |> MetaQueries.new() |> Repo.all()
    iex> ready_metas_with_fields = MetaQueries.list() |> MetaQueries.with_data_set_fields() |> MetaQueries.ready() |> Repo.all()
  """
  def list(), do: from(m in Meta)

  @doc """
  Preloads the `user` relation
  """
  @spec with_user(query :: Ecto.Queryset.t()) :: Ecto.Queryset.t()
  def with_user(query), do: from(m in query, preload: [user: :metas])

  @doc """
  Preloads the `data_set_fields` relation
  """
  @spec with_data_set_fields(query :: Ecto.Queryset.t()) :: Ecto.Queryset.t()
  def with_data_set_fields(query), do: from(m in query, preload: [data_set_fields: :meta])

  @doc """
  Preloads the `data_set_constraints` relation
  """
  @spec with_data_set_constraints(query :: Ecto.Queryset.t()) :: Ecto.Queryset.t()
  def with_data_set_constraints(query),
    do: from(m in query, preload: [data_set_constraints: :meta])

  @doc """
  Preloads the `virtual_date_fields` relation
  """
  @spec with_virtual_date_fields(query :: Ecto.Queryset.t()) :: Ecto.Queryset.t()
  def with_virtual_date_fields(query), do: from(m in query, preload: [virtual_date_fields: :meta])

  @doc """
  Preloads the `virtual_point_fields` relation
  """
  @spec with_virtual_point_fields(query :: Ecto.Queryset.t()) :: Ecto.Queryset.t()
  def with_virtual_point_fields(query),
    do: from(m in query, preload: [virtual_point_fields: :meta])

  @doc """
  Preloads the `data_set_diffs` relation
  """
  @spec with_data_set_diffs(query :: Ecto.Queryset.t()) :: Ecto.Queryset.t()
  def with_data_set_diffs(query), do: from(m in query, preload: [data_set_diffs: :meta])

  @doc """
  Preloads the `admin_user_notes` relation
  """
  @spec with_admin_user_notes(query :: Ecto.Queryset.t()) :: Ecto.Queryset.t()
  def with_admin_user_notes(query), do: from(m in query, preload: [admin_user_notes: :meta])

  @doc """
  Adds a filter to query selecting metas whose state is new
  """
  @spec new(query :: Ecto.Queryset.t()) :: Ecto.Queryset.t()
  def new(query), do: from(m in query, where: m.state == "new")

  @doc """
  Adds a filter to query selecting metas whose state is needs_approval
  """
  @spec needs_approval(query :: Ecto.Queryset.t()) :: Ecto.Queryset.t()
  def needs_approval(query), do: from(m in query, where: m.state == "needs_approval")

  @doc """
  Adds a filter to query selecting metas whose state is ready
  """
  @spec ready(query :: Ecto.Queryset.t()) :: Ecto.Queryset.t()
  def ready(query), do: from(m in query, where: m.state == "ready")

  @doc """
  Adds a filter to query selecting metas whose state is erred
  """
  @spec erred(query :: Ecto.Queryset.t()) :: Ecto.Queryset.t()
  def erred(query), do: from(m in query, where: m.state == "erred")

  @doc """
  Adds a filter to query limiting the results to a given number
  """
  @spec limit_to(query :: Ecto.Queryset.t(), limit :: integer) :: Ecto.Queryset.t()
  def limit_to(query, limit), do: from(m in query, limit: ^limit)

  @doc """
  Adds a filter to query selecting metas whose user's ID matches the given ID
  """
  @spec for_user(query :: Ecto.Queryset.t(), user :: %User{}) :: Ecto.Queryset.t()
  def for_user(query, user), do: from(m in query, where: m.user_id == ^user.id)

  @doc """
  Applies a series of query modifiers to a given query. This is used mostly in
  web controller list functions to allow for easy filtering.

  Available filter keys with their associated functions and argument types:

  | key name            | function                  | args types | default |
  | ------------------- | ------------------------- | ---------- | ------- |
  | with_user           | with_user                 | boolean    | false   |
  | with_fields         | with_data_set_fields      | boolean    | false   |
  | with_virtual_dates  | with_virtual_date_fields  | boolean    | false   |
  | with_virtual_points | with_virtual_point_fields | boolean    | false   |
  | with_constraints    | with_data_set_constraints | boolean    | false   |
  | with_diffs          | with_data_set_diffs       | boolean    | false   |
  | new                 | new                       | boolean    | false   |
  | needs_approval      | needs_approval            | boolean    | false   |
  | ready               | ready                     | boolean    | false   |
  | erred               | erred                     | boolean    | false   |
  | limit_to            | limit_to                  | integer    | nil     |
  | for_user            | for_user                  | %User{}    | nil     |

  ## Examples

    iex> my_first_5_ready_metas =
           MetaQueries.list()
           |> MetaQueries.handle_opts([
                for_user: me,
                with_user: true,
                ready: true,
                limit_to: 5])
           |> Repo.all()
  """
  @spec handle_opts(query :: Ecto.Queryset.t(), opts :: [{atom, any}]) :: Ecto.Queryset.t()
  def handle_opts(query, opts \\ []) do
    defaults = [
      with_user: false,
      with_fields: false,
      with_virtual_dates: false,
      with_virtual_points: false,
      with_constraints: false,
      with_diffs: false,
      with_notes: false,
      new: false,
      needs_approval: false,
      ready: false,
      erred: false,
      limit_to: nil,
      for_user: nil
    ]

    opts = Keyword.merge(defaults, opts)

    query
    |> cond_compose(opts[:with_user], MetaQueries, :with_user)
    |> cond_compose(opts[:with_fields], MetaQueries, :with_data_set_fields)
    |> cond_compose(opts[:with_virtual_dates], MetaQueries, :with_virtual_date_fields)
    |> cond_compose(opts[:with_virtual_points], MetaQueries, :with_virtual_point_fields)
    |> cond_compose(opts[:with_constraints], MetaQueries, :with_data_set_constraints)
    |> cond_compose(opts[:with_diffs], MetaQueries, :with_data_set_diffs)
    |> cond_compose(opts[:with_notes], MetaQueries, :with_admin_user_notes)
    |> cond_compose(opts[:new], MetaQueries, :new)
    |> cond_compose(opts[:needs_approval], MetaQueries, :needs_approval)
    |> cond_compose(opts[:ready], MetaQueries, :ready)
    |> cond_compose(opts[:erred], MetaQueries, :erred)
    |> filter_compose(opts[:limit_to], MetaQueries, :limit_to)
    |> filter_compose(opts[:for_user], MetaQueries, :for_user)
  end
end
