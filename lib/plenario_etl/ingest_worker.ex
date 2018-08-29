defmodule PlenarioEtl.IngestWorker do
  use GenStage

  require Integer

  require Logger

  alias Briefly
  alias Plenario.Actions.MetaActions

  # init

  def start_link, do: GenStage.start_link(__MODULE__, :ok)

  def init(:ok), do: {:consumer, %{}, subscribe_to: [PlenarioEtl.IngestQueue]}

  # server callbacks

  def handle_events(meta_ids, _from, state) do
    str_meta_ids = Enum.map(meta_ids, &Integer.to_string/1)
    Logger.info("IngestWorker #{inspect(self())}: processing #{inspect(str_meta_ids)}")

    updated =
      Enum.reduce(meta_ids, state, fn id, acc ->
        meta = MetaActions.get(id)
        Logger.info("IngestWorker #{inspect(self())}: working on #{inspect(meta.name)}")

        download_path = get_download_path(meta)
        sentinel_path = get_sentinel_path(meta)
        ensure_clean_paths(download_path, sentinel_path)
        download_fh = get_download_fh(download_path)

        %HTTPoison.AsyncResponse{id: reqid} =
          HTTPoison.get!(meta.source_url, [], stream_to: self())
        Logger.info("IngestWorker #{inspect(self())}: starting download of #{inspect(meta.name)} from #{inspect(meta.source_url)} with request id #{inspect(reqid)}")

        Map.merge(acc, %{reqid => {id, download_path, sentinel_path, download_fh}})
      end)

    {:noreply, [], updated}
  end

  def handle_info(%HTTPoison.AsyncStatus{id: reqid}, state) do
    Logger.debug("IngestWorker #{inspect(self())}: got async status for reqid=#{inspect(reqid)}")
    {:noreply, [], state}
  end

  def handle_info(%HTTPoison.AsyncHeaders{id: reqid}, state) do
    Logger.debug("IngestWorker #{inspect(self())}: got async headers for reqid=#{inspect(reqid)}")
    {:noreply, [], state}
  end

  def handle_info(%HTTPoison.AsyncChunk{id: reqid, chunk: chunk}, state) do
    Logger.debug("IngestWorker #{inspect(self())}: got async chunk for reqid=#{inspect(reqid)}")
    {_, _, _, fh} = Map.get(state, reqid)
    IO.binwrite(fh, chunk)
    {:noreply, [], state}
  end

  def handle_info(%HTTPoison.AsyncEnd{id: reqid}, state) do
    Logger.info("IngestWorker #{inspect(self())}: got async end for reqid=#{inspect(reqid)}")

    # stop the download, touch sentinel and close the file handler
    :hackney.stop_async(reqid)
    {id, download, sentinel, fh} = Map.get(state, reqid)
    File.touch!(sentinel)
    File.close(fh)

    # get the meta
    meta = MetaActions.get(id)

    # load the downloaded file into the database
    case meta.source_type do
      "csv" -> handle_csv(meta, download)
      "tsv" -> handle_csv(meta, download)
      "shp" -> handle_shapefile(meta, download)
    end

    # update the meta
    {:ok, _} = MetaActions.update_latest_import(meta, NaiveDateTime.utc_now())

    bbox = MetaActions.compute_bbox!(meta)
    {:ok, _} = MetaActions.update_bbox(meta, bbox)

    hull = MetaActions.compute_hull!(meta)
    {:ok, _} = MetaActions.update_hull(meta, hull)

    range = MetaActions.compute_time_range!(meta)
    {:ok, _} = MetaActions.update_time_range(meta, range)

    # clean up files
    File.rm(download)
    File.rm(sentinel)

    {:noreply, [], state}
  end

  # helpers

  defp get_download_path(meta) do
    Briefly.create!(prefix: "#{meta.slug}", extname: "DOWNLOAD")
  end

  defp get_sentinel_path(meta) do
    Briefly.create!(prefix: "#{meta.slug}", extname: "DONE")
  end

  defp ensure_clean_paths(d, s) do
    if File.exists?(d), do: File.rm!(d)
    if File.exists?(s), do: File.rm!(s)
  end

  defp get_download_fh(d) do
    File.touch!(d)
    File.open!(d, [:append, :utf8])
  end

  defp handle_csv(meta, download_path) do
    Plenario.Actions.DataSetActions.etl!(meta, download_path)
  end

  defp handle_shapefile(meta, download_path) do
    PlenarioEtl.Shapefile.load(download_path, meta.table_name)
  end
end
