defmodule Plenario2.Actions.ExportJobActions do
  import Ecto.Query
  alias Plenario2.Changesets.ExportJobChangesets
  alias Plenario2.Schemas.ExportJob
  alias Plenario2.Repo

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

  def list_for_user(user), do: Repo.all(from j in ExportJob, where: j.user_id == ^user.id)
end
