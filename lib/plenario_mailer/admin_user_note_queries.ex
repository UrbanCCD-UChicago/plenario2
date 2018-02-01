defmodule Plenario.Queries.AdminUserNoteQueries do
  @moduledoc """
  This module provides functions for building and composing Ecto
  queries. This is beneficial for streamlining the way we interact
  with the database from other business logic and web controller
  modules.
  """

  import Ecto.Query

  import Plenario.Queries.Utils

  alias Plenario.Schemas.AdminUserNote
  alias Plenario.Queries.AdminUserNoteQueries

  alias PlenarioAuth.User

  @typedoc """
  Parameter is an ID attribute
  """
  @type id :: String.t() | integer

  @doc """
  Creates a query for a single AdminUserNote entity in the database filtered by its ID
  """
  @spec from_id(id :: id) :: Ecto.Queryset.t()
  def from_id(id), do: from(n in AdminUserNote, where: n.id == ^id)

  @doc """
  Creates a query that gets all AdminUserNote entities in the database. This can be combined
  with other filters and preloads.

  ## Examples

    iex> my_unread_notes = AdminUserNoteQueries.list()
           |> AdminUserNoteQueries.for_user(me)
           |> unread()
           |> Repo.all()
  """
  def list(), do: from(n in AdminUserNote)

  @doc """
  Adds a filter to query selecting notes that have not been acknowledged
  """
  @spec unread(query :: Ecto.Queryset.t()) :: Ecto.Queryset.t()
  def unread(query), do: from(n in query, where: n.acknowledged == false)

  @doc """
  Adds a filter to query selecting notes that have been acknowledged
  """
  @spec acknowledged(query :: Ecto.Queryset.t()) :: Ecto.Queryset.t()
  def acknowledged(query), do: from(n in query, where: n.acknowledged == true)

  @doc """
  Adds a filter to query selecting notes whose user_id matches the ID of the user in the params
  """
  @spec for_user(query :: Ecto.Queryset.t(), user :: %User{}) :: Ecto.Queryset.t()
  def for_user(query, user), do: from(n in query, where: n.user_id == ^user.id)

  @doc """
  Orders the records returned by the query in descending order of their `inserted_at` value
  """
  @spec oldest_first(query :: Ecto.Queryset.t()) :: Ecto.Queryset.t()
  def oldest_first(query), do: from(n in query, order_by: [desc: n.inserted_at])

  @doc """
  Applies a series of query modifiers to a given query. This is used mostly in
  we controller list functions to allow for easy filtering.

  Available filter keys with their associated functions and argument types:

  | key name     | function     | arg types | default |
  | ------------ | ------------ | --------- | ------- |
  | unread       | unread       | boolean   | false   |
  | acknowledged | acknowledged | boolean   | false   |
  | for_user     | for_user     | %User{}   | nil     |
  | oldest       | oldest_first | boolean   | false   |

  ## Examples

    iex> my_unread_notes = AdminUserNoteQueries.list()
           |> AdminUserNoteQueries.handle_opts([
                for_user: me,
                unread: true
              ])
           |> Repo.all()
  """
  def handle_opts(query, opts \\ []) do
    defaults = [
      unread: false,
      acknowledged: false,
      for_user: nil,
      oldest: false
    ]

    opts = Keyword.merge(defaults, opts)

    query
    |> cond_compose(opts[:unread], AdminUserNoteQueries, :unread)
    |> cond_compose(opts[:acknowledged], AdminUserNoteQueries, :acknowledged)
    |> cond_compose(opts[:oldest_first], AdminUserNoteQueries, :oldest_first)
    |> filter_compose(opts[:for_user], AdminUserNoteQueries, :for_user)
  end
end
