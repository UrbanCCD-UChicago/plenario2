defmodule PlenarioEtl.Exporter do
  use GenServer

  alias Plenario.Actions.MetaActions
  alias PlenarioEtl.Actions.ExportJobActions
  alias PlenarioMailer.Emails

  import Plenario.Repo, only: [stream: 1, transaction: 1, update!: 1]
  import UUID, only: [uuid4: 0]

  require Logger

  @bucket Application.fetch_env!(:ex_aws, :bucket)
  @timeout 100_000

  @doc """
  Entrypoint for the `Exporter` `GenServer`. Saves you the hassle of writing out
  `GenServer.start_link`. Calls this module's `init/1` function.
  """
  def start_link(state) do
    GenServer.start_link(__MODULE__, state)
  end

  @doc """
  Sets the initial state of an individual worker.
  """
  def init(state) do
    {:ok, state}
  end

  @doc """
  Starts an `export/1` task by checking out a connection from the exporter
  worker pool. Can be awaited on.
  """
  def export_task(job) do
    export_fn = fn pid -> GenServer.call(pid, {:export, job}) end

    {:ok,
     Task.async(fn ->
       :poolboy.transaction(:exporter, export_fn, @timeout)
     end)}
  end

  @doc """
  Exposes the `export/1` logic as a GenServer call.
  """
  def handle_call({:export, job}, _, state) do
    {:reply, export(job), state}
  end

  @doc """
  Exports a dataset or a subset of data to s3 using the query provided in the
  `job`. The `state` value of `job` is managed by this function.
  """
  def export(job) do
    job =
      ExportJobActions.mark_started(job)
      |> update!()

    try do
      generate_stream(job)
      |> stream_to_local_storage()
      |> upload_to_s3()
      |> ExportJobActions.mark_completed()
      |> update!()
      |> send_success_email()
    catch
      reason ->
        Logger.error(inspect(reason, pretty: true))

        ExportJobActions.mark_erred(job, %{error_message: inspect(reason, pretty: true)})
        |> update!()

        send_failure_email(job)
    end
  end

  defp generate_stream(job) do
    {query, _} = Code.eval_string(job.query)
    Logger.info("[#{inspect(self())}] [generate_stream] Evaluating query: #{inspect query}")
    {job, stream(query)}
  end

  defp stream_to_local_storage({job, stream}) do
    path = "/tmp/#{inspect(uuid4())}"
    file = File.open!(path, [:write, :utf8])

    Logger.info("[#{inspect(self())}] [stream_to_local_storage] Writing to #{path}")
    transaction(fn ->
      stream
      |> CSV.encode(headers: header(job.meta))
      |> Enum.each(&IO.write(file, &1))
    end)

    {job, path}
  end

  defp upload_to_s3({job, path}) do
    Logger.info("[#{inspect(self())}] [upload_to_s3] Uploading to bucket #{@bucket}")
    Logger.info("[#{inspect(self())}] [upload_to_s3] At #{job.export_path}")

    result =
      path
      |> ExAws.S3.Upload.stream_file()
      |> ExAws.S3.upload(@bucket, job.export_path)
      |> ExAws.request!(region: "us-east-1")

    job
  end

  defp send_success_email(job) do
    Logger.info("[#{inspect(self())}] [send_email] Sending s3 link to user")
    export_link = "https://s3.amazonaws.com/#{@bucket}/#{job.export_path}"
    target_email = job.user.email
    message = "Success! Your export results can be downloaded at: #{export_link}"
    email = Emails.send_email(target_email, message)

    {job, email}
  end

  defp send_failure_email(job) do
    Logger.info("[#{inspect(self())}] [send_email] Sending error to user")
    target_email = job.user.email
    message = "Your export errored! Please contact the plenario folks."
    email = Emails.send_email(target_email, message)

    {job, email}
  end

  defp header(meta) do
    MetaActions.get_column_names(meta) |> Enum.map(&String.to_atom/1)
  end
end
