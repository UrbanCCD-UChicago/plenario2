defmodule Plenario2.Etl.Worker do
  @moduledoc """
  A `GenServer` responsible for ingesting a single dataset. It dies when it
  has succesfully ingested a dataset or when it errors. It conveys infromation
  about the ongoing ingest through updates to its state, which can be inspected
  with `:sys.get_state/1`.
  """

  import Ecto.Migration, only: [create: 2, table: 1, timestamps: 0]
  use GenServer

  @create_table_template "lib/plenario2/etl/templates/create_table.sql.eex"

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
  def init(state) do
    {:ok, state}
  end

  @doc """
  Downloads the file located at the `source_url` for our `state`. Updates
  `state` to include a `worker_downloaded_file_path` key with the location
  of the downloaded file.
  """
  def download(state) do
    %HTTPoison.Response{body: body} = HTTPoison.get!(state[:source_url])
    path = "/tmp/#{state[:name]}.csv"
    File.write!(path, body)
    Map.merge(state, %{worker_downloaded_file_path: path})
  end

  @doc """
  Stages a table for ingest. If the table does not exist, create the table with
  a schema defined by the `dataset_set_fields` key in our `state`. If it does
  exist but columns have been added, modify the table accordingly.
  """
  def stage(state) do
    sql = EEx.eval_file(@create_table_template, [state: state])
    Ecto.Adapters.SQL.query!(Plenario2.Repo, sql, [])
    state
  end
end
