defmodule PlenarioAot.AotWorker do
  use GenServer

  require Logger

  alias PlenarioAot.{AotActions}

  @timeout 1_000 * 60 * 5  # 5 minutes

  ##
  # CLIENT API

  def process_observation_batch(pid_or_name) do
    Logger.info("Starting ETL of AoT data")
    Enum.each(AotActions.list_metas(), fn meta ->
      GenServer.call(pid_or_name, {:process, meta}, @timeout)
    end)
  end

  ##
  # CALLBACK IMPLEMENTATION

  def start_link(_), do: GenServer.start_link(__MODULE__, nil, [])

  def init(state), do: {:ok, state}

  ##
  # SERVER IMPLEMENTATION

  def handle_call({:process, meta}, _, state) do
    {:ok, path} = Briefly.create()
    Logger.info("Starting download for AoT Network `#{meta.network_name}` from `#{meta.source_url}` to `#{path}`")

    %HTTPoison.Response{body: body} = HTTPoison.get!(meta.source_url)
    File.write!(path, body)

    Logger.info("Finished download for `#{meta.network_name}`")
    Logger.info("Starting to rip `#{path}` into `aot_data` table for AoT Network `#{meta.network_name}`")

    # todo(heyzoos) this needs to be streamed, otherwise we're going to keep seeing heap memory errors
    File.read!(path)
    |> Poison.decode!()
    |> Enum.each(fn json_payload ->
      case AotActions.insert_data(meta, json_payload) do
        {:error, cs} ->
          Logger.error("#{inspect(cs)}")
         _ ->
          :ok
      end
    end)

    Logger.info("Finished ripping `#{path}` for AoT Network `#{meta.network_name}`")
    Logger.info("Updating bbox for AoT Network `#{meta.network_name}`")

    case AotActions.compute_and_update_meta_bbox(meta) do
      :ok ->
        Logger.info("Finished updating bbox for AoT Network `#{meta.network_name}`")

      {:error, message} ->
        Logger.error(message)
    end

    Logger.info("Updating time_range for AoT Network `#{meta.network_name}`")

    case AotActions.compute_and_update_meta_time_range(meta) do
      :ok ->
        Logger.info("Finished updating time_range for AoT Network `#{meta.network_name}`")

      {:error, message} ->
        Logger.error(message)
    end

    {:reply, nil, state}
  end
end
