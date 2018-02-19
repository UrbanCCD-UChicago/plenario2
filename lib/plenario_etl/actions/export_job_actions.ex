defmodule PlenarioEtl.Actions.ExportJobActions do
  @moduledoc """
  This module provides a common API for the business logic
  underlying the various public interfaces for ExportJob.
  """

  import Ecto.Query


  alias PlenarioEtl.Changesets.ExportJobChangesets
  alias PlenarioEtl.Schemas.ExportJob

  alias Plenario.Repo

  alias Plenario.Schemas.User

  require Logger

  @typedoc """
  Returns a tuple of :ok, ExportJob or :error, Ecto.Changeset
  """
  @type ok_job :: {:ok, ExportJob} | {:error, Ecto.Changeset.T}

  @doc """
  Creates a new instance of ExportJob
  """
  @spec create(meta :: Meta | integer, user :: User | integer, query :: String.t(), include_diffs :: boolean) :: ok_job
  def create(meta, user, query, include_diffs) when not is_integer(meta), do: create(meta.id, user, query, include_diffs)
  def create(meta, user, query, include_diffs) when not is_integer(user), do: create(meta, user.id, query, include_diffs)
  def create(meta, user, query, include_diffs \\ false) when is_integer(meta) and is_integer(user) do
    params = %{
      meta_id: meta,
      user_id: user,
      query: query,
      include_diffs: include_diffs
    }

    Logger.info("Creating Export Job: #{inspect(params)}")

    ExportJobChangesets.create(params)
    |> Repo.insert()
  end

  @doc """
  Lists all entries for ExportJobs in the database, optionally filtered
  to only include results whose User relationship matches the `user` param.

  ## Examples

    all_exports = ExportJobActions.list()
    my_exports = ExportJobActions.list(me)
  """
  @spec list(user :: User | integer | nil) :: list(ExportJob)
  def list(), do: list(nil)
  def list(user) when not is_integer(user) and not is_nil(user), do: list(user.id)
  def list(user) when is_integer(user) or is_nil(user) do
    query =
      case is_nil(user) do
        true -> from(j in ExportJob)
        false -> from(j in ExportJob, where: j.user_id == ^user)
      end

    Repo.all(query)
  end
end
