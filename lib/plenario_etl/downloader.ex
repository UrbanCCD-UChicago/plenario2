defmodule PlenarioEtl.Downloader do
  use GenStage

  require Logger

  alias Plenario.Actions.MetaActions

  alias PlenarioEtl.FileRegistry

  # init

  def start_link, do: GenStage.start_link(__MODULE__, :ok, name: __MODULE__)

  def init(:ok), do: {:producer_consumer, :ok, subscribe_to: [PlenarioEtl.EtlQueue]}

  # server api

  def handle_events(meta_ids, _from, state) do
    Logger.debug("Downloader: handling #{inspect(meta_ids)}")

    meta_paths =
      Enum.map(meta_ids, fn meta_id ->
        Logger.info("Downloader: downloading source for #{inspect(meta_id)}")
        {download_path, sentinel_path} = download_source(meta_id)
        {meta_id, download_path, sentinel_path, self()}
      end)

    {:noreply, meta_paths, state}
  end

  def handle_info(%HTTPoison.AsyncStatus{id: reqid}, state) do
    Logger.debug("Downloader: got async status for reqid=#{inspect(reqid)}")
    {:noreply, [], state}
  end

  def handle_info(%HTTPoison.AsyncHeaders{id: reqid}, state) do
    Logger.debug("Downloader: got async headers for reqid=#{inspect(reqid)}")
    {:noreply, [], state}
  end

  def handle_info(%HTTPoison.AsyncChunk{id: reqid, chunk: chunk}, state) do
    Logger.debug("Downloader: got async chunk for reqid=#{inspect(reqid)}")
    fh = FileRegistry.get_download_fh(self())
    IO.binwrite(fh, chunk)
    {:noreply, [], state}
  end

  def handle_info(%HTTPoison.AsyncEnd{id: reqid}, state) do
    Logger.debug("Downloader: got async end for reqid=#{inspect(reqid)}")
    :hackney.stop_async(reqid)

    sentinel_path = FileRegistry.get_sentinel_path(self())
    File.touch!(sentinel_path)

    {:noreply, [], state}
  end

  # helpers

  defp download_source(meta_id) do
    meta = MetaActions.get(meta_id)
    %{download: download, sentinel: sentinel} = FileRegistry.add(self(), meta_id)

    Logger.debug("Downloader: for meta #{inspect(meta_id)}, downloading to #{inspect(download)}, waiting for sentinel at #{inspect(sentinel)}")

    %HTTPoison.AsyncResponse{id: reqid} = HTTPoison.get!(meta.source_url, [], stream_to: self())
    Logger.debug("Downloader: async response for #{meta_id} has reqid=#{inspect(reqid)}")

    {download, sentinel}
  end
end
