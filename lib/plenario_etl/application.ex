defmodule PlenarioEtl.Application do
  use Application

  alias PlenarioEtl.{
    FileRegistry,
    EtlQueue,
    Downloader,
    Ripper
}

  @pool_size Application.get_env(:plenario, PlenarioEtl)[:pool_size]

  def start_link, do: start(nil, nil)

  def start(_type, _state) do
    import Supervisor.Spec, warn: false

    children = [
      # exporter
      :poolboy.child_spec(:exporter, exporter_config()),

      # importer
      worker(FileRegistry, []),
      worker(EtlQueue, []),
      worker(Downloader, []),
      worker(Ripper, [])
    ]

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
      strategy: :one_for_one,
      name: PlenarioEtl.Supervisor
    ]
  end
end
