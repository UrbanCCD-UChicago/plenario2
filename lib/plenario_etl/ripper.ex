defmodule PlenarioEtl.Ripper do
  use GenStage

  require Logger

  alias Plenario.Actions.MetaActions

  alias PlenarioEtl.FileRegistry

  @sentinel_wait 200  # 200ms (5x second)

  # init

  def start_link, do: GenStage.start_link(__MODULE__, :ok, name: __MODULE__)

  def init(:ok), do: {:consumer, :ok, subscribe_to: [PlenarioEtl.Downloader]}

  # server api

  def handle_events(meta_paths, _from, state) do
    Logger.debug("Ripper: handling #{inspect(meta_paths)}")

    for {meta_id, download_path, sentinel_path, parent_pid} <- meta_paths do
      wait_for_sentinel(sentinel_path, parent_pid)

      meta = MetaActions.get(meta_id)

      case meta.source_type do
        "csv" -> handle_csv(meta, download_path)
        "tsv" -> handle_csv(meta, download_path)
        "shp" -> handle_shapefile(meta, download_path)
      end

      meta = MetaActions.get(meta_id)
      {:ok, _} = MetaActions.update_latest_import(meta, NaiveDateTime.utc_now())

      bbox = MetaActions.compute_bbox!(meta)
      {:ok, _} = MetaActions.update_bbox(meta, bbox)

      range = MetaActions.compute_time_range!(meta)
      {:ok, _} = MetaActions.update_time_range(meta, range)
    end

    {:noreply, [], state}
  end

  # helpers

  defp wait_for_sentinel(path, parent_pid) do
    case File.exists?(path) do
      true ->
        Logger.debug("Ripper: found sentinel #{inspect(path)}")
        FileRegistry.remove(parent_pid)
        :ok

      false ->
        Logger.debug("Ripper: waiting for sentinel #{inspect(path)}")
        Process.sleep(@sentinel_wait)
        wait_for_sentinel(path, parent_pid)
    end
  end

  defp handle_csv(meta, download_path) do
    Plenario.Actions.DataSetActions.etl!(meta, download_path)
  end

  defp handle_shapefile(meta, download_path) do
    PlenarioEtl.Shapefile.load(download_path, meta.table_name)
  end
end
