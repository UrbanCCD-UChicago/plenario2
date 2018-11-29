defmodule Plenario.Etl.Worker do
  use GenStage

  require Logger

  alias Plenario.DataSetActions

  alias Plenario.Etl.{
    Downloader,
    Queue
  }

  @pid __MODULE__

  # init

  def start_link, do: GenStage.start_link(@pid, :ok)

  def init(:ok), do: {:consumer, :ok, subscribe_to: [Queue]}

  # callbacks

  def handle_events(ds_ids, _from, state) do
    Enum.each(ds_ids, fn id ->
      ds = DataSetActions.get!(id)
      Logger.info("processing #{ds.name}", worker: "#{inspect(self())}")

      file = Downloader.download(ds)
      :ok = Plenario.Repo.etl!(ds, file)

      Logger.info("done with db load", data_set: ds.name, worker: "#{inspect(self())}")
      Logger.info("updating computed fields", data_set: ds.name, worker: "#{inspect(self())}")

      time_range = DataSetActions.compute_time_range!(ds)
      hull = DataSetActions.compute_hull!(ds)
      bbox = DataSetActions.compute_bbox!(ds)
      num_records = DataSetActions.get_num_records!(ds)

      {:ok, _} =
        DataSetActions.update ds,
          time_range: time_range,
          bbox: bbox,
          hull: hull,
          num_records: num_records,
          latest_import: NaiveDateTime.utc_now()

      try do
        File.rm!(file)
      rescue
        _ ->
          Logger.error("could not remove download #{file}")
      end

      Logger.info("done processing #{ds.name}", worker: "#{inspect(self())}")
    end)

    {:noreply, [], state}
  end
end
