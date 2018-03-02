defmodule PlenarioEtl.ScheduledJobs do

  require Logger

  import PlenarioEtl.Worker, only: [async_load!: 1]

  alias Plenario.Actions.MetaActions

  def refresh_datasets() do
    offset = Application.get_env(:plenario, :refresh_offest)
    now = DateTime.utc_now()
    last_check = Timex.shift(now, offset)

    Logger.info("[#{inspect self()}] [refresh_datasets] time bounds: now=#{now} last_check=#{last_check}")

    all_metas =
      MetaActions.list(only_ready: true)
      |> Enum.reject(fn m ->
        not is_nil(m.refresh_ends_on)
        and Date.compare(m.refresh_ends_on, now) == :lt
      end)

    never_imported = Enum.filter(all_metas, fn m ->
      not is_nil(m.refresh_rate)
      and is_nil(m.next_import)
    end)

    ready_now = Enum.filter(all_metas, fn m ->
      not is_nil(m.refresh_rate)
      and not is_nil(m.next_import)
      and Enum.member?([:gt, :ge], DateTime.compare(m.next_import, last_check))
      and Enum.member?([:lt, :le], DateTime.compare(m.next_import, now))
    end)

    metas = never_imported ++ ready_now
    names = for m <- metas, do: m.name
    Logger.info("[#{inspect self()}] [refresh_datasets] Refreshing #{length(metas)} datasets: #{inspect(names)}")

    Enum.map(metas, fn meta ->
      async_load!(meta.id)
    end)

    metas
  end
end
