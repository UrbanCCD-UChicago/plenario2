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
  Downloads the file located at the `source` with to /tmp/ with a file name
  of `name`. Returns path of downloaded file.

  ## Example

    iex> download!("file_name", "https://source.url/")
    "/tmp/file_name.csv"

  """
  @spec download!(name :: charlist, source :: charlist) :: charlist
  def download!(name, source) do
    %HTTPoison.Response{body: body} = HTTPoison.get!(source)
    path = "/tmp/#{name}.csv"
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
    path = download!(Meta.get_dataset_table_name(meta), meta.source_url())

    File.stream!(path)
    |> CSV.decode!()
    |> Stream.drop(1)
    |> Stream.chunk_every(100)
    |> Enum.map(fn chunk ->
         spawn_link(__MODULE__, :load_chunk!, [self(), meta, job, chunk])
       end)
    |> Enum.map(fn pid ->
         receive do
           {^pid, result} -> result
         end
       end)
  end

  def load_chunk!(sender, meta, job, rows) do
    existing_rows = contains!(meta, rows)
    inserted_rows = upsert!(meta, rows)
    pairs = Enum.zip(existing_rows, inserted_rows)

    result =
      Enum.map(pairs, fn {existing_row, inserted_row} ->
        create_diffs(meta, job, existing_row, inserted_row)
      end)

    send(sender, {self(), result})
  end

  @doc """
  Upsert a dataset with a chunk of `rows`. 

  ## Example

    iex> upsert!(meta, rows)
    # [[1, "inserted", "row"]]

  """
  @spec upsert!(meta :: Meta, rows :: list) :: list
  def upsert!(meta, rows) do
    template_query!(@upsert_template, meta, rows)
  end

  @doc """
  Query existing rows that might conflict with an insert query using `rows`.

  ## Example

    iex> upsert!(meta, rows)
    # [[1, "might", "conflict"]]

  """
  @spec contains!(meta :: Meta, rows :: list) :: list
  def contains!(meta, rows) do
    template_query!(@contains_template, meta, rows)
  end

  defp template_query!(template, meta, rows) do
    table = Meta.get_dataset_table_name(meta)
    columns = MetaActions.get_columns(meta)
    constraints = MetaActions.get_constraints(meta)

    sql =
      EEx.eval_file(
        template,
        table: table,
        columns: columns,
        rows: rows,
        constraints: constraints
      )

    %Postgrex.Result{rows: rows} = query!(Plenario2.Repo, sql, [])
    rows
  end

  def create_diffs(meta, job, original, updated) do
    table = Meta.get_dataset_table_name(meta)
    columns = MetaActions.get_columns(meta)
    constraint = MetaActions.get_constraint(meta)
    constraints = MetaActions.get_constraints(meta)

    constraint_indices =
      Enum.map(constraints, fn constraint ->
        Enum.find_index(columns, &(&1 == constraint))
      end)

    constraint_values =
      Enum.map(constraint_indices, fn index ->
        Enum.at(original, index)
      end)

    constraint_map = Enum.zip([constraints, constraint_values]) |> Map.new()

    List.zip([original, updated])
    |> Enum.with_index()
    |> Enum.map(fn {{original_value, updated_value}, index} ->
         if original_value !== updated_value do
           column = Enum.fetch!(columns, index)

           # TODO(heyzoos) inspect will render values in a way that is 
           # is probably unusable to end users. Need a way to guess the
           # correct string format for a value.

           {:ok, diff} =
             DataSetDiffActions.create(
               meta.id(),
               constraint.id(),
               job.id(),
               column,
               inspect(original_value),
               inspect(updated_value),
               DateTime.utc_now(),
               constraint_map
             )

           diff
         end
       end)
  end
end
