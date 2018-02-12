defmodule PlenarioEtl.Worker do
  @moduledoc """
  A `GenServer` responsible for ingesting a single dataset. It dies when it
  has succesfully ingested a dataset or when it errors. It conveys infromation
  about the ongoing ingest through updates to its state, which can be inspected
  with `:sys.get_state/1`.
  """

  use GenServer

  alias Plenario.{ModelRegistry, Repo}
  alias Plenario.Actions.{MetaActions, UniqueConstraintActions}
  alias PlenarioEtl.Actions.{DataSetDiffActions, EtlJobActions}
  alias PlenarioEtl.Rows

  import Ecto.Adapters.SQL, only: [query!: 3]
  import Ecto.Changeset
  import Ecto.Query
  import Ecto.Query.API

  require Logger

  @chunk_size Application.get_env(:plenario, PlenarioEtl)[:chunk_size]
  @contains_template "lib/plenario_etl/templates/contains.sql.eex"
  @upsert_template "lib/plenario_etl/templates/upsert.sql.eex"
  @timeout 10000

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
    Logger.info("[#{inspect(self())}] [init] Starting worker GenServer")
    {:ok, state}
  end

  def handle_call({:load, meta_id_map}, _, state) do
    Logger.info("[#{inspect(self())}] [handle_call] Received :load call")
    {:reply, load(meta_id_map), state}
  end

  def handle_call({:load_chunk!, meta, job, chunk, constraints}, _, state) do
    Logger.info("[#{inspect(self())}] [handle_call] Received :load_chunk! call")
    {:reply, load_chunk!(meta, job, chunk, constraints), state}
  end

  @doc """
  Downloads the file located at the `source` with to /tmp/ with a file name
  of `name`. Returns path of downloaded file.
  """
  @spec download!(name :: charlist, source :: charlist, type :: charlist) :: charlist
  def download!(name, source, type) do
    type =
      if type === "shp" do
        "zip"
      else
        type
      end

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
    job = EtlJobActions.get(state[:job_id])
    constraints = unique_constraints(meta)

    Logger.info("[#{inspect(self())}] [load] Downloading file for #{meta.name}")
    Logger.info("[#{inspect(self())}] [load] #{meta.name} source url is #{meta.source_url}")
    Logger.info("[#{inspect(self())}] [load] #{meta.name} source type is #{meta.source_type}")
    Logger.info("[#{inspect(self())}] [load] Using constraints #{constraints}")

    path =
      download!(
        meta.table_name,
        meta.source_url,
        meta.source_type
      )

    Logger.info("[#{inspect(self())}] [load] File stored at #{path}")

    case meta.source_type do
      "json" -> load_json(meta, path, job, constraints)
      "csv" -> load_csv(meta, path, job, constraints)
      "tsv" -> load_tsv(meta, path, job, constraints)
      "shp" -> load_shape(meta, path, job)
    end
  end

  @doc """
  This is the main subprocess kicked off by the `load` method that handles
  and ingests a smaller chunk of rows.
  """
  def load_chunk!(meta, job, rows, constraints) do
    Logger.info("[#{inspect(self())}] [load_chunk] Running contains query")
    existing_rows = contains!(meta, rows, constraints)

    Logger.info("[#{inspect(self())}] [load_chunk] Running upsert query")
    inserted_rows = upsert!(meta, rows, constraints)

    pairs = Rows.pair_rows(existing_rows, inserted_rows, constraints)
    Logger.info("[#{inspect(self())}] [load_chunk] Will possibly update #{Enum.count(pairs)} rows")

    Enum.map(pairs, fn {existing_row, inserted_row} ->
      create_diffs(meta, job, existing_row, inserted_row, constraints)
    end)
  end

  @doc """
  """
  def load_json(meta, path, job, constraint) do
    Logger.info("[#{inspect(self())}] [load_json] Prep loader for json at #{path}")

    load_data(meta, path, job, constraint, fn path ->
      File.read!(path)
      |> Poison.decode!()
    end)
  end

  @doc """
  """
  def load_csv(meta, path, job, constraint) do
    Logger.info("[#{inspect(self())}] [load_csv] Prep loader for csv at #{path}")

    load_data(meta, path, job, constraint, fn path ->
      File.stream!(path)
      |> CSV.decode!(headers: true)
    end)
  end

  @doc """
  """
  def load_tsv(meta, path, job, constraints) do
    Logger.info("[#{inspect(self())}] [load_tsv] Prep loader for tsv at #{path}")

    load_data(meta, path, job, constraints, fn path ->
      File.stream!(path)
      |> CSV.decode!(headers: true, separator: ?\t)
    end)
  end

  @doc """
  Performs the work of loading a shapefile associated with a `Meta` instance.
  """
  def load_shape(meta, path, _job) do
    Logger.info("[#{inspect(self())}] [load_shape] Unpacking shapefile at #{path}")
    {:ok, file_paths} = :zip.unzip(String.to_charlist(path), cwd: '/tmp/')

    Logger.info("[#{inspect(self())}] [load_shape] Looking for .shp file")

    shp =
      Enum.find(file_paths, fn path ->
        String.ends_with?(to_string(path), ".shp")
      end)
      |> to_string()

    Logger.info("[#{inspect(self())}] [load_shape] Prep loader for shapefile at #{shp}")
    PlenarioEtl.Shapefile.load(shp, meta.name)
  end

  defp load_data(meta, path, job, constraints, decode) do
    Logger.info("[#{inspect self()}] [load_data] Chunking rows and spawning children")

    columns =
      MetaActions.get_column_names(meta)
      |> Enum.map(&String.to_atom/1)
      |> Enum.sort()

    decode.(path)
    |> Stream.chunk_every(@chunk_size)
    |> Enum.map(fn chunk ->
      async_load_chunk!(meta, job, chunk, constraints)
    end)
    |> Enum.map(fn task ->
      Task.await(task)
    end)
  end

  def async_load_chunk!(meta, job, chunk, constraints) do
    Task.async(fn ->
      :poolboy.transaction(
        :worker,
        fn pid -> GenServer.call(pid, {:load_chunk!, meta, job, chunk, constraints}) end,
        @timeout
      )

      {:ok, self()}
    end)
  end

  def async_load!(meta_id) do
    meta = MetaActions.get(meta_id)
    job = EtlJobActions.create!(meta)
    {:ok, job} = EtlJobActions.mark_started(job)

    task = Task.async(fn ->
      :poolboy.transaction(
        :worker,
        fn pid ->
          try do
            GenServer.call(pid, {:load, %{
              meta_id: meta_id,
              job_id: job.id
            }})
            EtlJobActions.mark_completed(job)
          catch
            :exit, code ->
              EtlJobActions.mark_erred(job, %{error_message: inspect(code)})
          end
        end,
        :infinity
      )
    end)

    %{
      meta: meta,
      job: job,
      task: task
    }
  end

  @doc """
  Upsert a dataset with a chunk of `rows`.
  """
  def upsert!(meta, rows, constraints) do
    model = ModelRegistry.lookup(meta.slug)
    {struct, _} = Code.eval_quoted(quote do %unquote(model){} end)

    Enum.map(rows, fn row ->
      cast(struct, row, Map.keys(row))
      |> Repo.insert!(on_conflict: :replace_all, conflict_target: constraints)
    end)
  end

  @doc """
  Query existing rows that might conflict with an insert query using `rows`.
  """
  def contains!(meta, rows, constraints) do
    row_pks = 
      for row <- rows do 
        for constraint <- constraints do
          row[constraint]
        end
      end

    ModelRegistry.lookup(meta.slug)
    |> where([m], ^(for constraint <- constraints do field(m, constraint) end) in ^row_pks)
    |> Repo.all()
  end

  @doc """
  Currently the ugly duckling of the worker API, it generates diff entries
  for a pair of rows. Needs to be refactored into something smaller and
  more readable.
  """
  def create_diffs(meta, job, constraint, original, updated) do
    cons = List.first(UniqueConstraintActions.list(for_meta: meta))
    constraint_id = cons.id
    constraint_names = UniqueConstraintActions.get_field_names(cons)

    constraint_map =
      Enum.map(constraint_names, fn constraint_name ->
        constraint_name_atom = String.to_atom(constraint_name)
        {constraint_name, original[constraint_name_atom]}
      end)
      |> Map.new()

    List.zip([original, updated])
    |> Enum.map(fn {original_value, updated_value} ->
      if original_value !== updated_value do
        {column, original_value} = original_value
        {_column, updated_value} = updated_value

        Logger.info(
          "[#{inspect(self())}] [create_diffs] #{column}: #{inspect(original_value)} changed to #{
            inspect(updated_value)
          }"
        )

        # TODO(heyzoos) inspect will render values in a way that is
        # is probably unusable to end users. Need a way to guess the
        # correct string format for a value.

        {:ok, diff} =
          DataSetDiffActions.create(
            meta.id(),
            constraint_id,
            job.id(),
            Atom.to_string(column),
            inspect(original_value),
            inspect(updated_value),
            DateTime.utc_now(),
            constraint_map
          )

        diff
      end
    end)
  end

  defp unique_constraints(meta) do
    cons = List.first(UniqueConstraintActions.list(for_meta: meta))
    constraints = UniqueConstraintActions.get_field_names(cons)
    for constraint <- constraints, do: String.to_atom(constraint)
  end
end
