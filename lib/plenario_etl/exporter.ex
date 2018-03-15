defmodule PlenarioEtl.Exporter do
  use GenServer

  alias Plenario.Actions.MetaActions
  alias Plenario.Repo
  alias PlenarioEtl.Actions.ExportJobActions
  alias PlenarioMailer.Emails

  import Plenario.Repo
  import UUID, only: [uuid4: 0]

  require Logger

  @bucket Application.get_env(:plenario, :s3_export_bucket)

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
    export_fn = fn pid -> GenServer.call(pid, {:export, job}, :infinity) end

    {:ok,
     Task.async(fn ->
       :poolboy.transaction(:exporter, export_fn, :infinity)
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
    job = Repo.preload(job, [:meta, :user])

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
    Logger.info("Evaluating query: #{inspect query}")
    {job, stream(query, timeout: :infinity)}
  end

  defp stream_to_local_storage({job, stream}) do
    path = "/tmp/#{inspect(uuid4())}"
    file = File.open!(path, [:write, :utf8])

    Logger.info("Writing to #{path}")
    transaction(fn ->
      stream
      |> CSV.encode(headers: header(job.meta))
      |> Enum.each(&IO.write(file, &1))
    end, timeout: :infinity)

    {job, path}
  end

  defp upload_to_s3({job, path}) do
    Logger.info("Uploading to bucket #{@bucket}")
    Logger.info("At #{job.export_path}")

    path
    |> ExAws.S3.Upload.stream_file()
    |> ExAws.S3.upload(@bucket, job.export_path)
    |> ExAws.request!(region: "us-east-1")

    job
  end

  defp send_success_email(job) do
    export_link = "https://s3.amazonaws.com/#{@bucket}/#{job.export_path}"
    target_email = job.user.email

    Logger.info("Sending s3 link #{export_link}")
    Logger.info("Sending link to #{target_email}")

    message = "Success! Your export results can be downloaded at: #{export_link}"
    email = Emails.send_email(target_email, message)

    {job, email}
  end

  defp send_failure_email(job) do
    target_email = job.user.email
    Logger.info("Sending error to #{target_email}")
    job = ExportJobActions.get!(job.id)
    email = Emails.send_email(target_email, job.error_message)

    {job, email}
  end

  defp header(meta) do
    MetaActions.get_column_names(meta) |> Enum.map(&String.to_atom/1)
  end

  def handle_info({:delivered_email, email}, state) do
    Logger.info("Successfuly sent email #{inspect(email, pretty: true)}")
    {:noreply, state}
  end
end
