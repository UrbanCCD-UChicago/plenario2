defmodule PlenarioEtl.Worker do
  @moduledoc """
  """

  use GenServer

  require Logger

  alias Plenario.Actions.{DataSetActions, MetaActions}

  alias PlenarioEtl.Actions.EtlJobActions

  alias PlenarioEtl.Schemas.EtlJob

  @timeout 1_000 * 60 * 10  # 10 minutes

  # client api

  def process_etl_job(pid, %EtlJob{} = job) do
    Logger.info("starting etl", etl_job_id: job.id, meta_id: job.meta_id)
    GenServer.call(pid, {:process, job}, @timeout)
  end

  # server callbacks

  def start_link(_), do: GenServer.start_link(__MODULE__, nil, [])

  def init(state), do: {:ok, state}

  def handle_call({:process, job}, _, state) do
    # get the related meta
    meta = MetaActions.get(job.meta_id)

    # download the file
    path = download(meta)

    # process the file
    result =
      case meta.source_type do
        "csv" ->
          load_csv(meta, path)

        "tsv" ->
          load_csv(meta, path, "\t")

        "shp" ->
          load_shapefile(meta, path)
      end

    # update the etl job state
    case result do
      :ok ->
        EtlJobActions.mark_succeeded(job)

      _ ->
        EtlJobActions.mark_erred(job, [])
    end

    # reply
    {:reply, nil, state}
  end

  # helpers

  defp download(meta) do
    Logger.info("starting to download source file from #{meta.source_url}", meta_id: meta.id)

    %HTTPoison.Response{body: body} = HTTPoison.get!(meta.source_url)
    path =
      case meta.source_type do
        "shp" ->
          "/tmp/#{meta.slug}.zip"

        _ ->
          "/tmp/#{meta.slug}.#{meta.source_type}"
      end
    File.write!(path, body)

    Logger.info("download complete - file written to #{path}", meta_id: meta.id)

    path
  end

  defp load_csv(meta, path, delimiter \\ ",") do
    # tons of logging going on in the etl function
    try do
      DataSetActions.etl!(meta.id, path, delimiter: delimiter, headers?: true)
    rescue
      e in Postgrex.Error ->
        Logger.error("error loading csv data: #{inspect(Postgrex.Error.message(e))}", meta_id: meta.id)
        :error
    end
  end

  defp load_shapefile(meta, path) do
    Logger.info("using shp loader", meta_id: meta.id)

    {:ok, file_paths} = :zip.unzip(String.to_charlist(path), cwd: '/tmp/')

    Logger.info("Looking for .shp file", meta_id: meta.id)

    shp =
      Enum.find(file_paths, fn path ->
        String.ends_with?(to_string(path), ".shp")
      end)
      |> to_string()

    Logger.info("Prep loader for shapefile at #{shp}", meta_id: meta.id)

    case PlenarioEtl.Shapefile.load(shp, meta.table_name) do
      {:ok, _} ->
        Logger.info("successfully loaded shapefile", meta_id: meta.id)
        :ok

      {:error, error} ->
        Logger.error("erro loading shapefile: #{inspect(error)}", meta_id: meta.id)
        :error
    end
  end
end
