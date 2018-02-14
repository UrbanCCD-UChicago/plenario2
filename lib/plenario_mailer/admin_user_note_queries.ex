defmodule PlenarioMailer.Queries.AdminUserNoteQueries do
  @moduledoc """
  This module provides a stable API for composing Ecto Queries using the
  DataSetField schema. Functions included in this module can be used as-is or
  in pipes to compose/filter basic queries.

  This module also provides a :handle_opts function to streamline the
  application of composable queries. This is useful in higher level APIs where
  basic queries, such as :list, can also be filtered based on other parameters.
  """

  import Ecto.Query

  alias Plenario.Schemas.{Meta, User}

  alias Plenario.Queries.Utils

  alias PlenarioMailer.Schemas.AdminUserNote

  alias PlenarioMailer.Queries.AdminUserNoteQueries

  @doc """
  Creates and Ecto Query to list all the AdminUserNotes in the database.

  ## Example

    all_nots =
      AdminUserNoteQueries.list()
      |> Repo.all()
  """
  @spec list() :: Ecto.Query.t()
  def list(), do: (from n in AdminUserNote)

  @doc """
  A composable query that filters a given query to only include results
  whose acknowledged field is false.

  ## Example

    unread_notes =
      AdminUserNoteQueries.list()
      |> AdminUserNoteQueries.unread_only()
      |> Repo.all()
  """
  @spec unread_only(query :: Ecto.Query.t()) :: Ecto.Query.t()
  def unread_only(query), do: from n in query, where: n.acknowledged == false

  @doc """
  A composable query that filters a given query to only include results
  whose acknowledged field is true.

  ## Example

    read_notes =
      AdminUserNoteQueries.list()
      |> AdminUserNoteQueries.acknowledged_only()
      |> Repo.all()
  """
  @spec acknowledged_only(query :: Ecto.Query.t()) :: Ecto.Query.t()
  def acknowledged_only(query), do: from n in query, where: n.acknowledged == true

  @doc """
  A composable query that filters returned notes whose relation to User
  is the user passed as the filter value.
  """
  @spec for_user(query :: Ecto.Query.t(), user :: User | integer) :: Ecto.Query.t()
  def for_user(query, %User{} = user), do: for_user(query, user.id)
  def for_user(query, user), do: from n in query, where: n.user_id == ^user

  @doc """
  A composable query that filters returned notes whose relation to Meta
  is the meta passed as the filter value.
  """
  @spec for_meta(query :: Ecto.Query.t(), meta :: Meta | integer) :: Ecto.Query.t()
  def for_meta(query, %Meta{} = meta), do: for_meta(query, meta.id)
  def for_meta(query, meta), do: from n in query, where: n.meta_id == ^meta

  @doc """
  Conditionally applies boolean and filter composable queries to the given
  query.

  ## Params

  | key / function     | default value | default action     |
  | ------------------ | ------------- | ------------------ |
  | :unread_only       | false         | doesn't apply func |
  | :acknowledged_only | false         | doesn't apply func |
  | :for_user          | :dont_use_me  | doesn't apply func |
  | :for_meta          | :dont_use_me  | doesn't apply func |
  """
  @spec handle_opts(query :: Ecto.Query.t(), opts :: Keyword.t()) :: Ecto.Query.t()
  def handle_opts(query, opts \\ []) do
    defaults = [
      unread_only: false,
      acknowledged_only: false,
      for_user: :dont_use_me,
      for_meta: :dont_use_me
    ]

    opts = Keyword.merge(defaults, opts)

    query
    |> Utils.bool_compose(opts[:unread_only], AdminUserNoteQueries, :unread_only)
    |> Utils.bool_compose(opts[:acknowledged_only], AdminUserNoteQueries, :acknowledged_only)
    |> Utils.filter_compose(opts[:for_user], AdminUserNoteQueries, :for_user)
    |> Utils.filter_compose(opts[:for_meta], AdminUserNoteQueries, :for_meta)
  end
end
