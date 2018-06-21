defmodule PlenarioEtl.IngestQueue do
  use GenStage

  require Logger

  alias Plenario.Actions.MetaActions

  alias Plenario.Schemas.Meta

  # init

  def start_link, do: GenStage.start_link(__MODULE__, :ok, name: __MODULE__)

  def init(:ok), do: {:producer, {:queue.new(), 0}}

  # client api

  def push(meta_ids) when is_list(meta_ids), do: for meta_id <- meta_ids, do: push(meta_id)
  def push(%Meta{id: meta_id}), do: push(meta_id)
  def push(meta_id), do: GenStage.cast(__MODULE__, {:push, meta_id})

  def handle_cast({:push, meta_id}, {queue, pending_demand}) do
    Logger.info("IngestQueue: pushing #{inspect(meta_id)} onto queue")
    updated = :queue.in(meta_id, queue)

    meta = MetaActions.get(meta_id)
    if is_nil(meta.latest_import) do
      try do
        {:ok, _} = MetaActions.mark_first_import(meta)
      rescue
        e ->
          Logger.info("error to follow: latest import is nil, but meta is is ready state...")
          Logger.error(Exception.message(e))
      end
    end
    {:ok, _} = MetaActions.update_next_import(meta)

    dispatch_metas(updated, pending_demand, [])
  end

  # server api

  def handle_demand(demand, {queue, pending_demand}) do
    Logger.debug("IngestQueue: handling demand of #{demand} with #{:queue.len(queue)} metas in queue")
    dispatch_metas(queue, demand + pending_demand, [])
  end

  defp dispatch_metas(queue, 0, meta_ids) do
    {:noreply, Enum.reverse(meta_ids), {queue, 0}}
  end

  defp dispatch_metas(queue, demand, meta_ids) do
    case :queue.out(queue) do
      {{:value, meta_id}, updated} ->
        Logger.debug("IngestQueue: popped #{inspect(meta_id)} off the queue")
        dispatch_metas(updated, demand - 1, [meta_id | meta_ids])

      {:empty, queue} ->
        {:noreply, Enum.reverse(meta_ids), {queue, demand}}
    end
  end
end
