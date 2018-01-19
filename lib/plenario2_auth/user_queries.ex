defmodule Plenario2Auth.UserQueries do
  @moduledoc """
  This module handles creating queries, preloading relations
  and applying filters for the User schema. This is used by
  other business logic libraries and controllers.
  """

  import Ecto.Query

  alias Plenario2Auth.User

  @doc """
  Builds a queryset with a filter for the user's ID
  """
  @spec get_by_id(id :: integer) :: Ecto.Queryset.t()
  def get_by_id(id), do: from(u in User, where: u.id == ^id)

  @doc """
  Builds a queryset with a filter for the user's email address
  """
  @spec get_by_id(email :: String.t()) :: Ecto.Queryset.t()
  def get_by_email(email), do: from(u in User, where: u.email_address == ^email)

  @doc """
  Build a queryset for all users

  ## Examples

    iex> active_users = UserQueries.list() |> UserQueries.active() |> Repo.all()
    iex> admin_users = UserQueries.list() |> UserQueries.admin() |> Repo.all()
  """
  @spec list() :: Ecto.Queryset.t()
  def list(), do: from(u in User)

  @doc """
  Applies a filter to a query that asserts the user is active
  """
  @spec active(query :: Ecto.Queryset.t()) :: Ecto.Queryset.t()
  def active(query), do: from(u in query, where: u.is_active == true)

  @doc """
  Applies a filter to a query that asserts the user is archived
  """
  @spec active(query :: Ecto.Queryset.t()) :: Ecto.Queryset.t()
  def archived(query), do: from(u in query, where: u.is_active == false)

  @doc """
  Applies a filter to a query that asserts the user is trusted
  """
  @spec active(query :: Ecto.Queryset.t()) :: Ecto.Queryset.t()
  def trusted(query), do: from(u in query, where: u.is_trusted == true)

  @doc """
  Applies a filter to a query that asserts the user is an admin
  """
  @spec active(query :: Ecto.Queryset.t()) :: Ecto.Queryset.t()
  def admin(query), do: from(u in query, where: u.is_admin == true)

  @doc """
  Preloads the results to include the users' metas
  """
  @spec with_metas(query :: Ecto.Queryset.t()) :: Ecto.Queryset.t()
  def with_metas(query), do: from(u in query, preload: [metas: :metas])
end
