defmodule PlenarioAot.AotWorker do
  use GenServer

  require Logger

  alias PlenarioAot.{AotActions}

  # 5 minutes
  @timeout 1_000 * 60 * 5

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
    download_source(meta)
    |> parse_source()
    |> rip_payload()

    {:reply, nil, state}
  end

  defp download_source(meta) do
    Logger.info("Starting AoT download for #{meta.network_name}")

    resp = HTTPoison.get(meta.source_url, follow_redirect: true)

    case resp do
      {:ok, response} ->
        {:ok, path} = Briefly.create()

        Logger.debug("Payload being written to #{path} for #{meta.network_name}")

        File.write!(path, response.body)
        {path, meta}

      _ ->
        Logger.error("Non 200 response when trying to download #{meta.network_name}")
        :error
    end
  end

  defp parse_source(:error), do: :error

  defp parse_source({path, meta}) do
    Logger.info("Parsing source for #{meta.network_name}")

    parsed =
      File.read!(path)
      |> Poison.decode()

    case parsed do
      {:ok, payload} ->
        {payload, meta}

      {:error, {reason, char, pos}} ->
        Logger.error("JSON parse error: #{inspect(reason)} #{inspect(char)} #{inspect(pos)}")
        :error
    end
  end

  defp rip_payload(:error), do: :error

  defp rip_payload({payload, meta}) do
    Logger.info("Ripping payload for #{meta.network_name}")

    payload
    |> Enum.each(fn obs_set ->
      case AotActions.insert_data(meta, obs_set) do
        {:error, changeset} ->
          Logger.error("#{inspect(changeset)}")

        _ ->
          :ok
      end
    end)

    Logger.info("Computing and updating metadata for #{meta.network_name}")

    case AotActions.compute_and_update_meta_bbox(meta) do
      :ok ->
        :ok

      {:error, message} ->
        Logger.error(message)
    end

    case AotActions.compute_and_update_meta_time_range(meta) do
      :ok ->
        :ok

      {:error, message} ->
        Logger.error(message)
    end
  end
end
