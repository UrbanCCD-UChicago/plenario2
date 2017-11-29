defmodule Plenario2.Etl.Worker do
  @moduledoc """
  A `GenServer` responsible for ingesting a single dataset. It dies when it
  has succesfully ingested a dataset or when it errors. It conveys infromation
  about the ongoing ingest through updates to its state, which can be inspected
  with `:sys.get_state/1`.
  """

  alias Plenario2.Actions.{
    DataSetDiffActions,
    DataSetFieldActions,
  }

  import Ecto.Adapters.SQL, only: [query!: 3]
  use GenServer

  @contains_template "lib/plenario2/etl/templates/contains.sql.eex"
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
    stream = File.stream!(state[:worker_downloaded_file_path]) |> CSV.decode!()

    header =
      Enum.take(stream, 1)
      |> List.first()
      |> Enum.map(&String.trim/1)

    stream
    |> Stream.drop(1)
    |> Stream.chunk_every(100)
    |> Enum.map(fn chunk ->
         state = Map.merge(state, %{rows: chunk, columns: header})
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

    iex> upsert!(%{
    ...>   meta: %Meta{},
    ...>   table_name: "chicago_tree_trimmings",
    ...>   columns: ["pk", "datetime", "location", "data"]
    ...>   rows: [
    ...>     [1, "2017-01-01T00:00:00", "(0, 0)", "eh?"]
    ...>   ]
    ...> })

  """
  @spec upsert!(sender :: pid, state :: map) :: :ok
  def upsert!(sender, state) do
    %{
      meta: meta,
      table_name: table_name,
      rows: rows,
      columns: columns
    } = state

    # TODO(heyzoos) this will be moved to the process that spawns the upsert
    # subprocesses so that the query for dataset metadata is performed only
    # once
    fields = DataSetFieldActions.list_for_meta(meta)

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

  # TODO(heyzoos) this and upsert are really similar, refactor this
  @doc """
  Query all values whose primary key might clash with a candidate row.

  ## Example

    iex> contains!(%{
    ...>   meta: %Meta{},
    ...>   table_name: "chicago_tree_trimmings",
    ...>   rows: [
    ...>     [1, "2017-01-01T00:00:00", "(0, 0)"]
    ...>   ]
    ...> })

  """
  @spec contains!(sender :: pid, state :: map) :: :ok
  def contains!(sender, state) do
    %{
      meta: meta,
      table_name: table_name,
      rows: rows,
      columns: columns
    } = state

    # TODO(heyzoos) this will be moved to the process that spawns the upsert
    # subprocesses so that the query for dataset metadata is performed only
    # once
    fields = DataSetFieldActions.list_for_meta(meta)

    [pkfield | _] =
      Enum.filter(fields, fn field ->
        String.contains?(field.opts, "primary key")
      end)

    pkname = pkfield.name()

    {^pkname, pkindex} =
      Enum.with_index(columns)
      |> Enum.filter(fn {column, _} -> column == pkname end)
      |> List.first()

    incoming_pks = Enum.map(rows, &Enum.fetch!(&1, pkindex))

    sql =
      EEx.eval_file(
        @contains_template,
        table: table_name,
        columns: columns,
        rows: rows,
        pk: pkname,
        incoming_pks: incoming_pks
      )

    result = query!(Plenario2.Repo, sql, [])
    send(sender, {self(), result})
  end

  @spec create_diffs(
          meta_id :: integer,
          constraint_id :: integer,
          job_id :: integer,
          columns :: list,
          origin :: list,
          updated :: list
        ) :: list
  def create_diffs(meta_id, constraint_id, job_id, columns, original, updated) do
    List.zip([original, updated])
    |> Enum.with_index()
    |> Enum.map(fn {{original_value, updated_value}, index} ->
         if original_value !== updated_value do
           column = Enum.fetch!(columns, index)

           {:ok, diff} = DataSetDiffActions.create(
             meta_id,
             constraint_id,
             job_id,
             column,
             original_value,
             updated_value,
             DateTime.utc_now(),
             %{event_id: "my-unique-id"}
           )

           diff
         end
       end)
  end
end
