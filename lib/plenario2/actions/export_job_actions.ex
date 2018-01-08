defmodule Plenario2.Actions.ExportJobActions do
  @moduledoc """
  This module provides a common API for the business logic
  underlying the various public interfaces for ExportJob.
  """

  import Ecto.Query

  import Plenario2.Guards, only: [is_id: 1]

  alias Plenario2.Changesets.ExportJobChangesets
  alias Plenario2.Schemas.ExportJob
  alias Plenario2.Repo

  alias Plenario2Auth.User

  @typedoc """
  Parameter is an ID attribute
  """
  @type id :: String.t | integer

  @typedoc """
  Returns a tuple of :ok, ExportJob or :error, Ecto.Changeset
  """
  @type ok_job :: {:ok, ExportJob} | {:error, Ecto.Changeset.T}

  @doc """
  Creates a new instance of ExportJob
  """
  @spec create(meta :: Meta | id, user :: User | id, query :: String.t, include_diffs :: boolean) :: ok_job
  def create(meta, user, query, include_diffs \\ false) do
    meta_id =
      case is_id(meta) do
        true -> meta
        false -> meta.id
      end

    user_id =
      case is_id(user) do
        true -> user
        false -> user.id
      end

    params = %{
      meta_id: meta_id,
      user_id: user_id,
      query: query,
      include_diffs: include_diffs
    }

    ExportJobChangesets.create(params)
    |> Repo.insert()
  end

  @doc """
  Gets a list of all ExportJobs for a given User
  """
  @spec list_for_user(user :: User | id) :: list(ExportJob)
  def list_for_user(user) do
    user_id =
      case is_id(user) do
        true -> user
        false -> user.id
      end

    Repo.all(
      from j in ExportJob,
      where: j.user_id == ^user_id
    )
  end
end
