defmodule Plenario.Queries.UserQueries do
  @moduledoc """
  This module provides a stable API for composing Ecto Queries using the User
  schema. Functions included in this module can be used as-is or in pipes to
  compose/filter basic queries.

  This module also provides a :handle_opts function to streamline the
  application of composable queries. This is useful in higher level APIs where
  basic queries, such as :list, can also be filtered based on other parameters.
  """

  import Ecto.Query

  alias Plenario.Queries.{Utils, UserQueries}

  alias Plenario.Schemas.User

  @doc """
  Creates an Ecto Query to list all Users in the database.

  ## Example

    all_users =
      UserQueries.list()
      |> Repo.all()
  """
  @spec list() :: Ecto.Query.t()
  def list(), do: (from u in User)

  @doc """
  Creates an Ecto Query to get a single User from the database by either
  its id or email field.

  ## Examples

    user =
      UserQueries.get(123)
      |> Repo.one()

    user =
      UserQueries.get("test@example.com")
      |> Repo.one()
  """
  @spec get(id :: integer) :: Ecto.Query.t()
  def get(id) when is_integer(id), do: from u in User, where: u.id == ^id

  @spec get(email :: String.t()) :: Ecto.Query.t()
  def get(email) when is_bitstring(email), do: from u in User, where: u.email == ^email

  @doc """
  A composable query that filters a given query to only include results whose
  is_active attribute is true.

  ## Example

    UserQueries.list()
    |> UserQueries.active_only()
    |> Repo.all()
  """
  @spec active_only(query :: Ecto.Query.t()) :: Ecto.Query.t()
  def active_only(query), do: from u in query, where: u.is_active == true

  @doc """
  A composable query that filters a given query to only include results whose
  is_active attribute is false.

  ## Example

    UserQueries.list()
    |> UserQueries.archived_only()
    |> Repo.all()
  """
  @spec archived_only(query :: Ecto.Query.t()) :: Ecto.Query.t()
  def archived_only(query), do: from u in query, where: u.is_active == false

  @doc """
  A composable query that filters a given query to only include results whose
  is_admin attribute is false.

  ## Example

    UserQueries.list()
    |> UserQueries.regular_only()
    |> Repo.all()
  """
  @spec regular_only(query :: Ecto.Query.t()) :: Ecto.Query.t()
  def regular_only(query), do: from u in query, where: u.is_admin == false

  @doc """
  A composable query that filters a given query to only include results whose
  is_admin attribute is true.

  ## Example

    UserQueries.list()
    |> UserQueries.admins_only()
    |> Repo.all()
  """
  @spec admins_only(query :: Ecto.Query.t()) :: Ecto.Query.t()
  def admins_only(query), do: from u in query, where: u.is_admin == true

  @doc """
  A composable query that preloads the Metas related to the returned Users.
  """
  @spec with_metas(query :: Ecto.Query.t()) :: Ecto.Query.t()
  def with_metas(query), do: from u in query, preload: [metas: :user]

  @doc """
  Conditionally applies boolean and filter composable queries to the given
  query.

  ## Params

  | key / function  | default value | default action     |
  | --------------- | ------------- | ------------------ |
  | :active_only    | false         | doesn't apply func |
  | :archived_onnly | false         | doesn't apply func |
  | :regular_only   | false         | doesn't apply func |
  | :admins_only    | false         | doesn't apply func |
  | :with_metas     | false         | doesn't apply func |

  ## Examples

    active_users =
      UserQueries.list()
      |> UserQueries.handle_opts(active_only: true)

    archived_users =
      UserQueries.list()
      |> UserQueries.handle_opts(archived_only: true)
  """
  @spec handle_opts(query :: Ecto.Query.t(), opts :: Keyword.t()) :: Ecto.Query.t()
  def handle_opts(query, opts \\ []) do
    defaults = [
      active_only: false,
      archived_only: false,
      regular_only: false,
      admins_only: false,
      with_metas: false
    ]

    opts = Keyword.merge(defaults, opts)

    query
    |> Utils.bool_compose(opts[:active_only], UserQueries, :active_only)
    |> Utils.bool_compose(opts[:archived_only], UserQueries, :archived_only)
    |> Utils.bool_compose(opts[:regular_only], UserQueries, :regular_only)
    |> Utils.bool_compose(opts[:admins_only], UserQueries, :admins_only)
    |> Utils.bool_compose(opts[:with_metas], UserQueries, :with_metas)
  end
end
