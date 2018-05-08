defmodule PlenarioAot.AotApplication do
  use Application

  @pool_size Application.get_env(:plenario, PlenarioAot)[:pool_size]

  def start(_type, _state), do: start_link()

  def start_link do
    children = [
      :poolboy.child_spec(:aot_importer, importer_config())
    ]
    Supervisor.start_link(children, opts())
  end

  defp importer_config do
    [
      name: {:local, :aot_worker},
      worker_module: PlenarioAot.AotWorker,
      size: @pool_size
    ]
  end

  defp opts do
    [
      strategy: :one_for_one,
      name: PlenarioAot.AotSupervisor
    ]
  end
end
