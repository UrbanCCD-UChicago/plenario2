defmodule Plenario2Etl.Application do
  use Application

  defp config do
    [
      name: {:local, :worker},
      worker_module: Plenario2Etl.Worker,
      size: 1000,
      max_overflow: 2
    ]
  end

  defp opts do
    [
      strategy: :one_for_one,
      name: Plenario2Etl.Supervisor
    ]
  end

  def start(_type, _args) do
    children = [:poolboy.child_spec(:worker, config())]
    Supervisor.start_link(children, opts())
  end
end
