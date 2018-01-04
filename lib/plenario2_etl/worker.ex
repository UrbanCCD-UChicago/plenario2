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
  import Slug, only: [slugify: 1]
  require Logger
  use GenServer

  @contains_template "lib/plenario2_etl/templates/contains.sql.eex"
  @upsert_template "lib/plenario2_etl/templates/upsert.sql.eex"

  @doc """
  Entrypoint for the `Worker` `GenServer`. Saves you the hassle of writing out
  `GenServer.start_link`. Calls this module's `init/1` function.

  ## Example

    iex> worker = Worker.start_link(%{meta_id: 5})
    :ok

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

  ## Example

    iex> download!("file_name", "https://source.url/", "csv")
    "/tmp/file_name.csv"

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

  ## Example

    iex> load(%{
    ...>   meta_id: 4
    ...> })
    :ok

  """
  @spec load(state :: map) :: map
  def load(state) do
    meta = MetaActions.get_from_id(state[:meta_id])
    job = EtlJobActions.create!(meta.id)

    Logger.info("Downloading file for #{meta.name}")
    Logger.info("#{meta.name} source url is #{meta.source_url}")
    Logger.info("#{meta.name} source type is #{meta.source_type}")

    path =
      download!(
        MetaActions.get_data_set_table_name(meta),
        meta.source_url,
        meta.source_type
      )

    Logger.info("File stored at #{path}")

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

  ## Example

    iex> load_chunk!(self(), meta, job, [["some", "rows"]])
    :ok

  """
  def load_chunk!(sender, meta, job, chunk) do
    rows = Enum.map(chunk, &Keyword.values/1)
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
  """
  def load_json(meta, path, job) do
    load_data(meta, path, job, fn path ->
      File.read!(path)
      |> Poison.decode!()
    end)
  end

  @doc """
  """
  def load_csv(meta, path, job) do
    load_data(meta, path, job, fn path ->
      File.stream!(path)
      |> CSV.decode!(headers: true)
    end)
  end

  @doc """
  """
  def load_tsv(meta, path, job) do
    load_data(meta, path, job, fn path ->
      File.stream!(path)
      |> CSV.decode!(headers: true, separator: ?\t)
    end)
  end

  @doc """
  """
  def load_shape(meta, path, job) do
  end

  defp set_srid(%Geo.Polygon{coordinates: coordinates}, srid) do
    %Geo.Polygon{coordinates: coordinates, srid: srid}
  end

  defp load_data(meta, path, job, decode) do
    decode.(path)
    |> Stream.map(&Enum.to_list/1)
    |> Stream.map(&Enum.sort/1)
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

  @doc """
  Upsert a dataset with a chunk of `rows`. 

  ## Example

    iex> upsert!(meta, rows)
    [[1, "inserted", "row"]]

  """
  @spec upsert!(meta :: Meta, rows :: list) :: list
  def upsert!(meta, rows) do
    template_query!(@upsert_template, meta, rows)
  end

  @doc """
  Query existing rows that might conflict with an insert query using `rows`.

  ## Example

    iex> upsert!(meta, rows)
    [[1, "might", "conflict"]]

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

  ## Example

    iex> create_diffs!(meta, job, ["a", "b", "c"], ["1", "2", "3"])
    [%DataSetDiff{}, ...]

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
