defmodule Plenario2.Actions.ExportJobActions do
  @moduledoc """
  This module provides a common API for the business logic
  underlying the various public interfaces for ExportJob.
  """

  import Ecto.Query

  alias Plenario2.Changesets.ExportJobChangesets
  alias Plenario2.Schemas.ExportJob
  alias Plenario2.Repo

  alias Plenario2Auth.User

  @doc """
  Creates a new instance of ExportJob
  """
  @spec create(meta_id :: integer, user_id :: integer, query :: String.t, include_diffs :: boolean) :: {:ok, %ExportJob{} | :error, Ecto.Changeset.t}
  def create(meta_id, user_id, query, include_diffs \\ false) do
    params = %{
      meta_id: meta_id,
      user_id: user_id,
      query: query,
      include_diffs: include_diffs
    }

    ExportJobChangesets.create(%ExportJob{}, params)
    |> Repo.insert()
  end

  @doc """
  Gets a list of all ExportJobs for a given User
  """
  @spec list_for_user(user :: %User{}) :: [%ExportJob{}]
  def list_for_user(user), do: Repo.all(from j in ExportJob, where: j.user_id == ^user.id)
end
