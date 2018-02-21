defmodule PlenarioEtl.Application do
  use Application

  @pool_size Application.get_env(:plenario, PlenarioEtl)[:pool_size]

  def start(_type, _state) do
    start_link()
  end

  def start_link do
    children = [
      :poolboy.child_spec(:importer, importer_config()),
      :poolboy.child_spec(:exporter, exporter_config())
    ]

    Supervisor.start_link(children, opts())
  end

  defp importer_config() do
    [
      name: {:local, :worker},
      worker_module: PlenarioEtl.Worker,
      size: @pool_size
    ]
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
