defmodule PlenarioEtl.Exporter do
  alias Ecto.Changeset
  alias Plenario.Repo
  alias Plenario.Actions.MetaActions
  
  @bucket Application.get_env(:ex_aws, Plenario)[:bucket]

  def export(job) do
    try do
      generate_stream(job)
      |> stream_to_local_storage()
      |> upload_to_s3()
      |> set_attachment()
      |> complete()
    catch :exit, code ->
      error(job, inspect(code))
    end
  end

  def generate_stream(job) do
    {query, _} = Code.eval_string(job.query)
    {job, Repo.stream(query)}
  end

  def stream_to_local_storage({job, stream}) do
    path = "/tmp/#{inspect UUID.uuid4}"
    file = File.open!(path, [:write, :utf8])
    columns = 
      MetaActions.get_column_names(job.meta) 
      |> Enum.map(&String.to_atom/1)

    Repo.transaction(fn ->
      stream
      |> CSV.encode(headers: columns)
      |> Enum.each(&IO.write(file, &1))
    end)
    
    {job, path}
  end

  def upload_to_s3({job, path}) do
    result =
      path
      |> ExAws.S3.Upload.stream_file()
      |> ExAws.S3.upload(@bucket, job.export_path) 
      |> ExAws.request!()
    {job, result[:body]}
  end

  def set_attachment({job, xml}) do
    job
    |> Changeset.cast(%{export_path: xml}, [:export_path])
    |> Repo.update!()
    job
  end

  def complete(job) do
    job
  end

  def error(job, _message) do
    job
  end
end
