defmodule PlenarioEtl do
  use Quantum.Scheduler, otp_app: :plenario

  require Logger

  import Ecto.Query

  alias Plenario.Repo

  alias Plenario.Schemas.Meta

  alias PlenarioEtl.EtlQueue

  def find_data_sets do
    query =
      from m in Meta,
      where: fragment("? in ('ready', 'awaiting_first_import')", m.state),
      where: fragment("? <= now()", m.refresh_starts_on),
      where: is_nil(m.refresh_ends_on) or fragment("? >= now()", m.refresh_ends_on),
      where: is_nil(m.next_import) or fragment("? <= now()", m.next_import)

    Repo.all(query)
  end

  def import_data_sets do
    metas = find_data_sets()
    Logger.info("importing #{length(metas)} -- #{inspect(Enum.map(metas, & &1.name))}")

    Enum.map(metas, fn meta ->
      EtlQueue.push(meta)
    end)
  end

  def import_data_set_on_demand(meta) do
    EtlQueue.push(meta)
  end
end
