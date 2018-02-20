defmodule PlenarioEtl.Exporter do
  alias Plenario.Actions.MetaActions
  alias PlenarioEtl.Actions.ExportJobActions

  import Plenario.Repo, only: [stream: 1, transaction: 1]
  import UUID, only: [uuid4: 0]

  require Logger
  
  @bucket Application.fetch_env!(:ex_aws, :bucket)

  def export(job) do
    ExportJobActions.mark_started(job)
    try do
      generate_stream(job)
      |> stream_to_local_storage()
      |> upload_to_s3()
      |> ExportJobActions.mark_completed()
    catch :exit, reason ->
      Logger.error(inspect(reason, pretty: true))
      ExportJobActions.mark_erred(job, 
        %{error_message: inspect(reason, pretty: true)})
    end
  end

  def generate_stream(job) do
    {query, _} = Code.eval_string(job.query)
    {job, stream(query)}
  end

  def stream_to_local_storage({job, stream}) do
    path = "/tmp/#{inspect uuid4()}"
    file = File.open!(path, [:write, :utf8])

    transaction(fn ->
      stream
      |> CSV.encode(headers: header(job.meta))
      |> Enum.each(&IO.write(file, &1))
    end)
    
    {job, path}
  end

  def upload_to_s3({job, path}) do
    Logger.info("[#{inspect(self())}] [upload_to_s3] Bucket: #{inspect @bucket}, Path: #{inspect job.export_path}")

    result =
      path
      |> ExAws.S3.Upload.stream_file()
      |> ExAws.S3.upload(@bucket, job.export_path) 
      |> ExAws.request!(region: "us-east-1")

    job
  end

  defp header(meta) do
    MetaActions.get_column_names(meta) |> Enum.map(&String.to_atom/1)
  end
end
