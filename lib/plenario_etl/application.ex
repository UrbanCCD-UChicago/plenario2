defmodule PlenarioEtl.Application do
  use Application

  @pool_size Application.get_env(:plenario, PlenarioEtl)[:pool_size]

  defp config do
    [
      name: {:local, :worker},
      worker_module: PlenarioEtl.Worker,
      size: @pool_size,
      max_overflow: 0
    ]
  end

  defp opts do
    [
      strategy: :one_for_one,
      name: PlenarioEtl.Supervisor
    ]
  end

  def start_link do
    children = [:poolboy.child_spec(:worker, config())]
    Supervisor.start_link(children, opts())
  end
end
