defmodule Plenario2.Etl.Worker do
  @moduledoc """
  A `GenServer` responsible for ingesting a single dataset. It dies when it
  has succesfully ingested a dataset or when it errors. It conveys infromation
  about the ongoing ingest through updates to its state, which can be inspected
  with `:sys.get_state/1`.
  """

  alias Plenario2.Actions.{
    DataSetFieldActions,
    VirtualDateFieldActions,
    VirtualPointFieldActions
  }

  import Ecto.Adapters.SQL, only: [query!: 3]
  import Ecto.Migration, only: [create: 2, table: 1, timestamps: 0]
  use GenServer

  @upsert_template "lib/plenario2/etl/templates/upsert.sql.eex"

  @doc """
  Entrypoint for the `Worker` `GenServer`. Saves you the hassle of writing out
  `GenServer.start_link`. Calls this module's `init/1` function.

  ## Example

    iex> alias Plenario2.Etl.Worker
    nil
    iex> worker = 
    ...>   Worker.start_link(%{
    ...>     name: "reports",
    ...>     source_url: "https://reports.org/download"
    ...>     data_set_fields: %{}
    ...>   })
  """
  def start_link(state) do
    GenServer.start_link(__MODULE__, state)
  end

  @doc """
  Runs once when the `Worker` is starting and sets the state of the server.
  The `state` is a map that contains all the information necessary to ingest a
  dataset.
  """
  @spec init(state :: map) :: {:ok, map}
  def init(state) do
    {:ok, state}
  end

  @doc """
  Downloads the file located at the `source_url` for our `state`. Updates
  `state` to include a `worker_downloaded_file_path` key with the location
  of the downloaded file.

  ## Example

    iex> download(%{
    ...>   meta: %Meta{},
    ...>   table_name: "chicago_tree_trimmings"
    ...> })

  """
  @spec download(state :: map) :: map
  def download(state) do
    %{
      meta: meta,
      table_name: table_name
    } = state

    %HTTPoison.Response{body: body} = HTTPoison.get!(meta.source_url)
    path = "/tmp/#{table_name}.csv"
    File.write!(path, body)
    Map.merge(state, %{worker_downloaded_file_path: path})
  end

  @doc """
  Upsert dataset rows from the file specified in `state`. Operations are
  performed in parallel on chunks of the file stream. The first line of 
  the file is skipped, assumed to be a header.
  """
  @spec load(state :: map) :: map
  def load(state) do
    File.stream!(state[:worker_downloaded_file_path])
    |> Stream.drop(1)
    |> CSV.decode!()
    |> Stream.chunk_every(100)
    |> Enum.map(fn chunk ->
         state = Map.merge(state, %{rows: chunk})
         spawn(__MODULE__, :upsert!, [self(), state])
       end)
    |> Enum.map(fn pid ->
         receive do
           {^pid, result} -> result
         end
       end)
  end

  @doc """
  Upsert a chunk of rows. It's worth nothing that because Postgres wants
  you to be explicit about what you update, this method updates all fields
  with the exception of the table's primary key.

  ## Example

    iex> download(%{
    ...>   meta: %Meta{},
    ...>   table_name: "chicago_tree_trimmings",
    ...>   rows: [
    ...>     [1, "2017-01-01T00:00:00", "(0, 0)"]
    ...>   ]
    ...> })
  """
  @spec upsert!(sender :: pid, state :: map) :: :ok
  def upsert!(sender, state) do
    %{
      meta: meta,
      table_name: table_name,
      rows: rows
    } = state

    # TODO(heyzoos) this will be moved to the process that spawns the upsert
    # subprocesses so that the query for dataset metadata is performed only
    # once
    fields = DataSetFieldActions.list_for_meta(meta)

    columns =
      for field <- fields do
        field.name
      end

    [pkfield | _] =
      Enum.filter(fields, fn field ->
        String.contains?(field.opts, "primary key")
      end)

    sql =
      EEx.eval_file(
        @upsert_template,
        table: table_name,
        columns: columns,
        rows: rows,
        pk: pkfield.name
      )
    
    result = query!(Plenario2.Repo, sql, [])
    send(sender, {self(), result})
  end
end
