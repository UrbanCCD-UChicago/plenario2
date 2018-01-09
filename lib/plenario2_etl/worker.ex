defmodule Plenario2Etl.Worker do
  @moduledoc """
  A `GenServer` responsible for ingesting a single dataset. It dies when it
  has succesfully ingested a dataset or when it errors. It conveys infromation
  about the ongoing ingest through updates to its state, which can be inspected
  with `:sys.get_state/1`.
  """

  alias Plenario2.Actions.{
    DataSetDiffActions,
    EtlJobActions,
    MetaActions
  }

  import Ecto.Adapters.SQL, only: [query!: 3]
  require Logger
  use GenServer

  @contains_template "lib/plenario2_etl/templates/contains.sql.eex"
  @upsert_template "lib/plenario2_etl/templates/upsert.sql.eex"

  @doc """
  Entrypoint for the `Worker` `GenServer`. Saves you the hassle of writing out
  `GenServer.start_link`. Calls this module's `init/1` function.
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
    {:ok, load(state)}
  end

  @doc """
  Downloads the file located at the `source` with to /tmp/ with a file name
  of `name`. Returns path of downloaded file.
  """
  @spec download!(name :: charlist, source :: charlist, type :: charlist) :: charlist
  def download!(name, source, type) do
    %HTTPoison.Response{body: body} = HTTPoison.get!(source)
    path = "/tmp/#{name}.#{type}"
    File.write!(path, body)
    path
  end

  @doc """
  Upsert dataset rows from the file specified in `state`. Operations are
  performed in parallel on chunks of the file stream. The first line of
  the file is skipped, assumed to be a header.
  """
  @spec load(state :: map) :: map
  def load(state) do
    meta = MetaActions.get(state[:meta_id])
    job = EtlJobActions.create!(meta.id)

    Logger.info("[#{inspect self()}] [load] Downloading file for #{meta.name}")
    Logger.info("[#{inspect self()}] [load] #{meta.name} source url is #{meta.source_url}")
    Logger.info("[#{inspect self()}] [load] #{meta.name} source type is #{meta.source_type}")

    path =
      download!(
        MetaActions.get_data_set_table_name(meta),
        meta.source_url,
        meta.source_type
      )

    Logger.info("[#{inspect self()}] [load] File stored at #{path}")

    case meta.source_type do
      "json" -> load_json(meta, path, job)
      "csv" -> load_csv(meta, path, job)
      "tsv" -> load_tsv(meta, path, job)
      "shp" -> load_shape(meta, path, job)
    end
  end

  @doc """
  This is the main subprocess kicked off by the `load` method that handles
  and ingests a smaller chunk of rows.
  """
  def load_chunk!(sender, meta, job, chunk) do
    rows = Enum.map(chunk, &Keyword.values/1)

    Logger.info("[#{inspect self()}] [load_chunk] Running contains query")
    existing_rows = contains!(meta, rows)

    Logger.info("[#{inspect self()}] [load_chunk] Running upsert query")
    inserted_rows = upsert!(meta, rows)
    pairs = Enum.zip(existing_rows, inserted_rows)

    Logger.info("[#{inspect self()}] [load_chunk] Will possibly update #{Enum.count(pairs)} rows")
    result =
      Enum.map(pairs, fn {existing_row, inserted_row} ->
        create_diffs(meta, job, existing_row, inserted_row)
      end)

    send(sender, {self(), result})
  end

  @doc """
  """
  def load_json(meta, path, job) do
    Logger.info("[#{inspect self()}] [load_json] Prep loader for json at #{path}")
    load_data(meta, path, job, fn path ->
      File.read!(path)
      |> Poison.decode!()
    end)
  end

  @doc """
  """
  def load_csv(meta, path, job) do
    Logger.info("[#{inspect self()}] [load_csv] Prep loader for csv at #{path}")
    load_data(meta, path, job, fn path ->
      File.stream!(path)
      |> CSV.decode!(headers: true)
    end)
  end

  @doc """
  """
  def load_tsv(meta, path, job) do
    Logger.info("[#{inspect self()}] [load_tsv] Prep loader for tsv at #{path}")
    load_data(meta, path, job, fn path ->
      File.stream!(path)
      |> CSV.decode!(headers: true, separator: ?\t)
    end)
  end

  @doc """
  Performs the work of loading a shapefile associated with a `Meta` instance.

  ## Examples

      iex> {:ok, user} = Plenario2Auth.UserActions.create("a", "b", "c@email.com")
      iex> {:ok, meta} = Plenario2.Actions.MetaActions.create("watersheds", user.id, "foo")
      iex> {:ok, job} = Plenario2.Actions.EtlJobActions.create(meta.id)
      iex> path = "test/fixtures/Watersheds.shp"
      iex> Plenario2Etl.Worker.load_shape(meta, path, job)
      {:ok, "watersheds"}

  """
  def load_shape(meta, path, _job) do
    Logger.info("[#{inspect self()}] [load_shape] Prep loader for shapefile at #{path}")
    Plenario2Etl.Shapefile.load(path, meta.name)
  end

  defp load_data(meta, path, job, decode) do
    Logger.info("[#{inspect self()}] [load_data] Chunking rows and spawning children")
    decode.(path)
    |> Stream.map(&Enum.to_list/1)
    |> Stream.map(&Enum.sort/1)
    |> Stream.chunk_every(100)
    |> Enum.map(fn chunk ->
         pid = spawn_link(__MODULE__, :load_chunk!, [self(), meta, job, chunk])
        Logger.info("[#{inspect self()}] [load_data] Spawned #{inspect pid}")
        pid
       end)
    |> Enum.map(fn pid ->
         receive do
           {^pid, result} -> result
         end
       end)
  end

  @doc """
  Upsert a dataset with a chunk of `rows`.
  """
  @spec upsert!(meta :: Meta, rows :: list) :: list
  def upsert!(meta, rows) do
    template_query!(@upsert_template, meta, rows)
  end

  @doc """
  Query existing rows that might conflict with an insert query using `rows`.
  """
  @spec contains!(meta :: Meta, rows :: list) :: list
  def contains!(meta, rows) do
    template_query!(@contains_template, meta, rows)
  end

  defp template_query!(template, meta, rows) do
    table = MetaActions.get_data_set_table_name(meta)
    columns = MetaActions.get_column_names(meta) |> Enum.sort()
    constraints = MetaActions.get_first_constraint_field_names(meta)

    sql =
      EEx.eval_file(
        template,
        table: table,
        columns: columns,
        rows: rows,
        constraints: constraints
      )

    # TODO(heyzoos) log informative messages for failing queries
    %Postgrex.Result{rows: rows} = query!(Plenario2.Repo, sql, [])
    rows
  end

  @doc """
  Currently the ugly duckling of the worker API, it generates diff entries
  for a pair of rows. Needs to be refactored into something smaller and
  more readable.
  """
  def create_diffs(meta, job, original, updated) do
    columns = MetaActions.get_column_names(meta)
    constraint = MetaActions.get_first_constraint(meta)
    constraints = MetaActions.get_first_constraint_field_names(meta)

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
           Logger.info("[#{inspect self()}] [create_diffs] diff: #{inspect original_value} changed to #{inspect updated_value}")
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
