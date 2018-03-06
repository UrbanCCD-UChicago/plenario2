defmodule PlenarioEtl.ScheduledJobs do

  require Logger

  import PlenarioEtl.Worker, only: [async_load!: 1]

  import Ecto.Query

  alias Plenario.Schemas.Meta

  alias Plenario.Repo

  def refresh_datasets() do
    offset = Application.get_env(:plenario, :refresh_offest)
    now = %DateTime{DateTime.utc_now() | second: 0, microsecond: {0, 0}}
    last_check = Timex.shift(now, offset)

    Logger.info("time bounds: now=#{now} last_check=#{last_check}")

    query =
      from m in Meta,
      where:
        m.state == "ready"
        and fragment("? <= ?::timestamptz", m.refresh_starts_on, ^now)
        and (
          is_nil(m.refresh_ends_on)
          or fragment("? >= ?::timestamptz", m.refresh_ends_on, ^now)
        )
        and (
          is_nil(m.next_import)
          or fragment("? between ?::timestamptz and ?::timestamptz", m.next_import, ^last_check, ^now)
        )

    q = Ecto.Adapters.SQL.to_sql(:all, Repo, query)
    Logger.info("running query: #{inspect(q)}")
    metas = Repo.all(query)
    names = for m <- metas, do: m.name
    Logger.info("refreshing #{length(metas)} datasets: #{inspect(names)}")

    Enum.map(metas, fn meta ->
      async_load!(meta.id)
    end)

    metas
  end
end
