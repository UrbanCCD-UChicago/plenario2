defmodule PlenarioEtl.Application do
  use Application

  alias PlenarioEtl.{IngestQueue, IngestWorker}

  @pool_size Application.get_env(:plenario, PlenarioEtl)[:pool_size]

  @num_ingest_workers Application.get_env(:plenario, PlenarioEtl)[:num_ingest_workers]

  def start_link, do: start(nil, nil)

  def start(_type, _state) do
    import Supervisor.Spec, warn: false

    children = [
      # exporter
      :poolboy.child_spec(:exporter, exporter_config()),

      # importer
      worker(IngestQueue, []),
    ]

    ingest_workers = Enum.map(1..@num_ingest_workers, fn i -> worker(IngestWorker, [], id: String.to_atom("worker_#{i}")) end)
    children = children ++ ingest_workers

    Supervisor.start_link(children, opts())
  end

  defp exporter_config() do
    [
      name: {:local, :exporter},
      worker_module: PlenarioEtl.Exporter,
      size: @pool_size
    ]
  end

  defp opts do
    [
      strategy: :rest_for_one,
      name: PlenarioEtl.Supervisor
    ]
  end
end
