defmodule Plenario2.Etl.ScheduledJobs do
  import Ecto.Query
  alias Plenario2.Core.Schemas.Meta
  alias Plenario2.Repo

  def find_refreshable_metas() do
    offset = Application.get_env(:plenario2, :refresh_offest)
    starts = DateTime.utc_now()
    ends = Timex.shift(starts, offset)

    Repo.all(
      from m in Meta,
      where: m.refresh_starts_on <= ^starts,
      where: is_nil(m.refresh_ends_on) or m.refresh_ends_on >= ^ends,
      where: m.next_refresh >= ^starts,
      where: m.next_refresh < ^ends
    )
  end
end
