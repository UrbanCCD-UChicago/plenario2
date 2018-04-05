defmodule PlenarioEtl.ScheduledJobs do

  require Logger

  import Ecto.Query

  alias Plenario.Schemas.Meta

  alias Plenario.Repo

  def refresh_datasets() do
    offset = Application.get_env(:plenario, :refresh_offest)
    now = %DateTime{DateTime.utc_now() | second: 0, microsecond: {0, 0}}
    last_check = Timex.shift(now, offset)

    query =
      from m in Meta,
      where:
        fragment("? in ('ready', 'awaiting_first_import')", m.state)
        and fragment("? <= ?::timestamptz", m.refresh_starts_on, ^now)
        and (
          is_nil(m.refresh_ends_on)
          or fragment("? >= ?::timestamptz", m.refresh_ends_on, ^now)
        )
        and (
          is_nil(m.next_import)
          or fragment("? between ?::timestamptz and ?::timestamptz", m.next_import, ^last_check, ^now)
        )

    metas = Repo.all(query)
    names = for m <- metas, do: m.name

    if length(metas) > 0 do
      Logger.info("refreshing #{length(metas)} datasets: #{inspect(names)}")
      Logger.info("time bounds: now=#{now} last_check=#{last_check}")
    end

    Enum.map(metas, fn meta ->
      PlenarioEtl.ingest(meta)
    end)

    metas
  end
end
