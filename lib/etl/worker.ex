defmodule EtlJob do
  use GenServer

  require Logger

  alias Plenario.Actions.MetaActions

  alias PlenarioEtl.Actions.EtlJobActions

  alias PlenarioEtl.Schemas.EtlJob

  @chunk_size 100

  # client api

  def process_etl_job(pid_or_name, %EtlJob{} = job) do
    meta = MetaActions.get(job.meta_id)
    Logger.info("processing etl job #{job.id} for meta #{meta.id}")

    GenServer.cast(pid_or_name, {:process, {job, meta}})
  end

  # callback implementation

  def handle_cast({:process, {job, meta}}, state) do
    # download
    filepath = download!(meta)

    # get decoder func
    stream =
      case meta.source_type do
        "csv" -> decode_csv!(filepath)
        "tsv" -> decode_tsv!(filepath)
        "json" -> decode_json!(filepath)
        "shp" -> decode_shp!(filepath)
      end

    # stream/read, decode, chunk, and async load to db
    tasks =
      stream
      |> Stream.chunk_every(@chunk_size)
      |> Enum.reduce([], fn chunk, acc ->
        task = Task.async(fn ->
          load_chunk!(chunk, meta.slug)
        end)
        acc ++ [task]
      end)

    # wait for async loads to finish
    task_results = Task.yield_many(tasks)
    exits =
      Enum.filter(task_results, fn {stat, _} -> stat == :exit end)

    if length(exits) == 0 do
      EtlJobActions.mark_success(job)
    else
      fail_stacks =
        for {_, reason} <- exits do
          reason
        end
      if length(exits) == length(task_results) do
        EtlJobActions.mark_failure(job, fail_stacks)
      else
        EtlJobActions.mark_partial_success(job, fail_stacks)
      end
    end

    # throw back response
    {:noreply, state}
  end

  defp download!(meta) do
    type =
      case meta.source_type == "shp" do
        true -> "zip"
        false -> meta.source_type
      end

    %HTTPoison.Response{body: body} = HTTPoison.get!(meta.source_url)
    path = "/tmp/#{meta.slug}.#{type}"
    File.write!(path, body)

    path
  end

  defp decode_csv!(filepath) do
    File.stream!(filepath)
    |> CSV.decode!(headers: true)
  end

  defp decode_tsv!(filepath) do
    File.stream!(filepath)
    |> CSV.decode!(headers: true, separator: ?\t)
  end

  defp decode_json!(filepath) do
    File.read!(filepath)
    |> Poison.decode!()
  end

  defp decode_shp!(filepath) do
    "i'll do this crazy shit later"
  end

  defp load_chunk!(chunk, slug) do
    # look up the model in the registry and then loads
    # the chunks into the database
  end

  # behaviour implementation

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, [])
  end

  def init(_) do
    Logger.info("starting etl worker")
    {:ok, []}
  end
end
