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
    EtlJobActions,
    MetaActions
  }

  alias Plenario2.Schemas.Meta

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
  @spec download(state :: map) :: charlist
  def download(state) do
    %{
      meta: meta,
      table_name: table_name
    } = state

    %HTTPoison.Response{body: body} = HTTPoison.get!(meta.source_url)
    path = "/tmp/#{table_name}.csv"
    File.write!(path, body)

    path
  end

  @doc """
  Upsert dataset rows from the file specified in `state`. Operations are
  performed in parallel on chunks of the file stream. The first line of 
  the file is skipped, assumed to be a header.

  ## Example

    iex> load(%{
    ...>   meta_id: 4
    ...> })

  """
  @spec load(state :: map) :: map
  def load(state) do
    meta =
      MetaActions.get_by_pk_preload(state[:meta_id], [
        :data_set_constraints,
        :data_set_fields
      ])

    job = EtlJobActions.create!(meta.id)
    columns = MetaActions.get_columns(meta)
    temp_file_path = download(state)

    # TODO(heyzoos) I'm expecting the first constraint to be the primary
    # key - it's jank but it'll have to do for now
    [constraint | _] = meta.data_set_constraints()
    constraint = constraint.field_names()

    state =
      Map.merge(state, %{
        job_id: job.id,
        columns: columns,
        table_name: Meta.get_dataset_table_name(meta),
        constraint: constraint
      })

    File.stream!(temp_file_path)
    |> CSV.decode!()
    |> Stream.drop(1)
    |> Stream.chunk_every(100)
    |> Enum.map(fn chunk ->
         state = Map.merge(state, %{rows: chunk})
         spawn_link(__MODULE__, :load_chunk!, [self(), state])
       end)
    |> Enum.map(fn pid ->
         receive do
           {^pid, result} -> IO.inspect("Received #{result}!")
         end
       end)
  end

  def load_chunk!(sender, state) do
    %{
      meta_id: meta_id,
      job_id: job_id,
      columns: columns,
      table_name: table,
      rows: rows,
      constraint: constraint
    } = state

    # existing_rows = contains!(columns, table, )
    inserted_rows = upsert!(table, columns, rows, constraint)

    # IO.inspect(existing_rows)
    IO.inspect(inserted_rows)

    # result = Enum.zip(existing_rows, inserted_rows)
    # |> Enum.map(fn {existing_row, inserted_row} ->
    #   constraint_id = %{}
    #   create_diffs(
    #     meta_id,
    #     constraint_id,
    #     job_id,
    #     columns,
    #     existing_row, 
    #     inserted_row
    #   )
    # end)

    send(sender, %{})
  end

  @doc """
  Upsert a chunk of rows. It's worth nothing that because Postgres wants
  you to be explicit about what you update, this method updates all fields
  with the exception of the table's primary key.

  ## Example

    iex> upsert!()

  """
  @spec upsert!(
    table :: charlist,
    columns :: list[charlist],
    rows :: list,
    constraint :: list[charlist]
  ) :: list
  def upsert!(table, columns, rows, constraint) do
    sql =
      EEx.eval_file(
        @upsert_template,
        table: table,
        columns: columns,
        rows: rows,
        pk: constraint
      )

    %Postgrex.Result{rows: rows} = query!(Plenario2.Repo, sql, [])
    rows
  end

  @doc """
  Query all values whose primary key might clash with a candidate row.

  ## Example

    iex> contains!()

  """
  @spec contains!(
    table :: charlist, 
    columns :: list[charlist], 
    rows :: list,
    constraint :: list[charlist]
  ) :: list
  def contains!(table, columns, rows, constraint) do
    IO.puts(
      sql =
        EEx.eval_file(
          @contains_template,
          table: table,
          columns: columns,
          pks: rows,
          constraint: constraint
        )
    )

    %Postgrex.Result{rows: rows} = query!(Plenario2.Repo, sql, [])
    rows
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

           {:ok, diff} =
             DataSetDiffActions.create(
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
