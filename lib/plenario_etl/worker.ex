defmodule PlenarioEtl.Worker do
  use GenServer

  require Logger

  import Ecto.Changeset

  alias Plenario.Repo

  alias Plenario.ModelRegistry

  alias Plenario.Actions.{MetaActions, UniqueConstraintActions}

  alias PlenarioEtl.Actions.EtlJobActions

  alias PlenarioEtl.Schemas.EtlJob

  @timeout 1_000 * 60 * 5  # 5 minutes

  # client api

  def process_etl_job(pid_or_name, %EtlJob{} = job) do
    Logger.info("starting etl process", etl_job: job.id)
    GenServer.call(pid_or_name, {:process, job}, @timeout)
  end

  # callback implementation

  def start_link(_), do: GenServer.start_link(__MODULE__, nil, [])

  def init(state) do
    {:ok, state}
  end

  # server implementation

  def handle_call({:process, job}, _, state) do
    meta = MetaActions.get(job.meta_id)

    # download the source document
    path = download!(meta)

    # get the model
    model = ModelRegistry.lookup(meta.slug)
    {model, _} = Code.eval_quoted(quote do %unquote(model){} end)
    Logger.info("got model for data set")

    # get column names and constraints
    columns =
      MetaActions.get_column_names(meta)
      |> Enum.map(fn c -> String.to_atom(c) end)
    Logger.info("got columns for model -> #{inspect(columns)}")

    constraints =
      UniqueConstraintActions.list(for_meta: meta)
      |> List.first()
      |> UniqueConstraintActions.get_field_names()
      |> Enum.map(fn c -> String.to_atom(c) end)
    Logger.info("got constraints for model -> #{inspect(constraints)}")

    # load data
    {outcome, errors} =
      case meta.source_type do
        "json" -> load_json!(path, model, columns, constraints)
        "csv" -> load_csv!(path, model, columns, constraints)
        "tsv" -> load_tsv!(path, model, columns, constraints)
        "shp" -> load_shp!(path, meta)
      end

    # update the job
    case outcome do
      :succeeded ->
        EtlJobActions.mark_succeeded(job)

      :partial_success ->
        EtlJobActions.mark_partial_success(job, errors)

      :erred ->
        EtlJobActions.mark_erred(job, errors)
    end

    # dump
    {:reply, nil, state}
  end

  defp download!(meta) do
    Logger.info("starting source document download")
    ext =
      case meta.source_type == "shp" do
        true -> "zip"
        false -> meta.source_type
      end

    %HTTPoison.Response{body: body} = HTTPoison.get!(meta.source_url)
    path = "/tmp/#{meta.slug}.#{ext}"
    File.write!(path, body)

    Logger.info("download stored at #{path}")

    path
  end

  defp load_json!(path, model, columns, constraints) do
    Logger.info("using json loader")

    load!(model, path, columns, constraints, fn pth ->
      File.read!(pth)
      |> Poison.decode!()
    end)
  end

  defp load_csv!(path, model, columns, constraints) do
    Logger.info("using csv loader")

    load!(model, path, columns, constraints, fn pth ->
      File.stream!(pth)
      |> CSV.decode!(headers: true)
    end)
  end

  defp load_tsv!(path, model, columns, constraints) do
    Logger.info("using tsv loader")

    load!(model, path, columns, constraints, fn _pth ->
      File.stream!(path)
      |> CSV.decode!(headers: true, separator: ?\t)
    end)
  end

  defp load_shp!(path, meta) do
    Logger.info("using shp loader")

    {:ok, file_paths} = :zip.unzip(String.to_charlist(path), cwd: '/tmp/')

    Logger.info("Looking for .shp file")

    shp =
      Enum.find(file_paths, fn path ->
        String.ends_with?(to_string(path), ".shp")
      end)
      |> to_string()

    Logger.info("Prep loader for shapefile at #{shp}")
    case PlenarioEtl.Shapefile.load(shp, meta.table_name) do
      {:ok, _} -> {:succeeded, nil}
      {:error, error} -> {:erred, error}
    end
  end

  defp load!(model, path, columns, constraints, decode) do
    Logger.info("ripping file")

    results =
      decode.(path)
      |> Enum.reduce([], fn row, acc ->
        Logger.debug("#{inspect(row)}")

        res =
          cast(model, row, columns)
          |> Repo.insert(on_conflict: :replace_all, conflict_target: constraints)

        Logger.debug("#{inspect(res)}")

        case res do
          {:error, message} ->
            Logger.error("error loading row -> #{inspect(message)}")

          _ -> :ok
        end

        acc ++ [res]
      end)

    len_results = length(results)

    Logger.info("upserted #{len_results} rows")
    Logger.debug("#{inspect(results)}")

    errors = Enum.filter(results, fn {status, _} -> status == :error end)
    len_errors = length(errors)

    Logger.info("there were #{len_errors} erroneous upserts")
    Logger.debug("#{inspect(errors)}")

    case len_errors == 0 do
      true -> {:succeeded, nil}
      false ->
        case len_errors == len_results do
          true -> {:erred, errors}
          false -> {:partial_success, errors}
        end
    end
  end
end
