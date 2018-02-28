defmodule PlenarioEtl.ScheduledJobs do
  alias Plenario.Schemas.Meta
  alias Plenario.Repo

  import Ecto.Query
  import PlenarioEtl.Worker, only: [async_load!: 1]

  require Logger

  def refresh_datasets() do
    offset = Application.get_env(:plenario, :refresh_offest)
    starts = DateTime.utc_now()
    ends = Timex.shift(starts, offset)

    metas = Repo.all(
      from m in Meta,
        where: m.refresh_starts_on <= ^starts,
        where: is_nil(m.refresh_ends_on) or m.refresh_ends_on >= ^ends,
        where: m.next_import >= ^starts,
        where: m.next_import < ^ends
    )

    Logger.info("[#{inspect self()}] [refresh_datasets] Refreshing #{length(metas)} datasets")

    Enum.map(metas, fn meta ->
      async_load!(meta.id)
    end)

    metas
  end
end
