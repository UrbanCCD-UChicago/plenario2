defmodule PlenarioEtl.FileRegistry do
  use GenServer

  require Logger

  alias Plenario.Actions.MetaActions

  # init

  def start_link, do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  def init(:ok), do: {:ok, %{}}

  # client api

  def add(downloader_pid, meta_id) do
    Logger.debug("FileRegistry: adding {#{inspect(downloader_pid)}, #{inspect(meta_id)}}")
    GenServer.call(__MODULE__, {:add, downloader_pid, meta_id})
  end

  def get_download_fh(downloader_pid) do
    Logger.debug("FileRegistry: getting download file handler for #{inspect(downloader_pid)}")
    GenServer.call(__MODULE__, {:get_download_fh, downloader_pid})
  end

  def get_sentinel_path(downloader_pid) do
    Logger.debug("FileRegistry: getting sentinel path for #{inspect(downloader_pid)}")
    GenServer.call(__MODULE__, {:get_sentinel_path, downloader_pid})
  end

  def remove(downloader_pid) do
    Logger.debug("FileRegistry: removing paths and entry for #{inspect(downloader_pid)}")
    GenServer.cast(__MODULE__, {:remove, downloader_pid})
  end

  # server api

  def handle_cast({:remove, downloader_pid}, state) do
    paths = Map.get(state, downloader_pid)
    download_fh = Map.get(paths, :download_fh)

    File.close(download_fh)

    updated_state = Map.delete(state, downloader_pid)
    {:noreply, updated_state}
  end

  def handle_call({:add, downloader_pid, meta_id}, _from, state) do
    meta = MetaActions.get(meta_id)
    download = make_download_path(meta)
    sentinel = make_sentinel_path(meta)

    if File.exists?(download), do: File.rm!(download)
    if File.exists?(sentinel), do: File.rm!(sentinel)

    File.touch!(download)
    download_fh = File.open!(download, [:append])

    updated_state = Map.merge(state, %{downloader_pid => %{download: download, sentinel: sentinel, download_fh: download_fh}})
    {:reply, %{download: download, sentinel: sentinel}, updated_state}
  end

  def handle_call({:get_download_fh, downloader_pid}, _from, state) do
    case Map.get(state, downloader_pid) do
      %{download_fh: download_fh} ->
        {:reply, download_fh, state}
      _ ->
        {:reply, nil, state}
    end
  end

  def handle_call({:get_sentinel_path, downloader_pid}, _from, state) do
    case Map.get(state, downloader_pid) do
      %{sentinel: sentinel_path} ->
        {:reply, sentinel_path, state}
      _ ->
        {:reply, nil, state}
    end
  end

  # helpers

  defp make_download_path(meta) do
    ext =
      case meta.source_type do
        "shp" -> "zip"
        _     -> meta.source_type
      end
    "/tmp/#{meta.slug}.#{ext}"
  end

  defp make_sentinel_path(meta), do: "/tmp/#{meta.slug}.done"
end
