defmodule Plenario.Etl.Queue do
  use GenStage

  require Logger

  alias Plenario.{
    DataSet,
    DataSetActions
  }

  @pid __MODULE__

  @clean_state {:queue.new(), 0}

  # init

  def start_link, do: GenStage.start_link(@pid, :ok, name: @pid)

  def init(:ok), do: {:producer, @clean_state}

  # client api

  def push(ids) when is_list(ids), do: for id <- ids, do: push(id)
  def push(%DataSet{id: id}), do: push(id)
  def push(id), do: GenStage.cast(@pid, {:push, id})

  def clear, do: GenStage.cast(@pid, :clear)

  # callbacks

  def handle_cast(:clear, _), do: {:noreply, @clean_state}

  def handle_cast({:push, id}, {queue, pending_demand}) do
    ds = DataSetActions.get!(id)
    Logger.info("pushing #{ds.name} onto queue")

    # add id to queue
    updated = :queue.in(id, queue)

    # update next import attr
    next = DataSetActions.compute_next_import!(ds, NaiveDateTime.utc_now())

    opts =
      case ds.first_import do
        nil -> [first_import: NaiveDateTime.utc_now(), next_import: next]
        _ -> [next_import: next]
      end

    {:ok, _} = DataSetActions.update(ds, opts)

    # dispatch
    dispatch(updated, pending_demand, [])
  end

  def handle_demand(demand, {queue, pending_demand}) do
    Logger.info("queue buffering demand of #{demand} with pending demand of #{pending_demand} and #{:queue.len(queue)} current items")
    dispatch(queue, demand + pending_demand, [])
  end

  defp dispatch(queue, 0, dsids), do: {:noreply, Enum.reverse(dsids), {queue, 0}}

  defp dispatch(queue, demand, dsids) do
    case :queue.out(queue) do
      {{:value, id}, updated} ->
        Logger.info("queue popped #{id}")
        dispatch(updated, demand - 1, [id | dsids])

      {:empty, queue} ->
        {:noreply, Enum.reverse(dsids), {queue, demand}}
    end
  end
end
