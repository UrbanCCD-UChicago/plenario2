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
    file = File.open!("test.csv", [:write, :utf8])
    columns = MetaActions.get_column_names(job.meta) |> Enum.map(&String.to_atom/1)

    IO.inspect Repo.transaction(fn ->
      stream |> Enum.to_list()

      stream
      |> CSV.encode(headers: columns)
      |> Enum.each(&IO.write(file, &1))
    end)
    
    {job, file}
  end

  def upload_to_s3({job, file}) do
    attachment =
      ExAws.S3.put_object(@bucket, job.export_path, file) 
      |> ExAws.request!()
    
    job
    |> Changeset.cast(%{export_path: attachment}, [:export_path])
    |> Repo.update!()

    job
  end

  def complete(job) do
    job
  end

  def error(job, _message) do
    job
  end

  defp erl_dt_to_naive_dt({{y, m, d}, {h, min, s}}) do
    NaiveDateTime.from_erl!({{y, m, d}, {h, min, s}})
  end
  defp erl_dt_to_naive_dt(pair), do: pair
end
