defmodule Plenario.Application do
  @moduledoc false

  use Application

  @num_etl_workers Application.get_env(:plenario, Plenario.Etl)[:num_workers]

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      supervisor(Plenario.Repo, []),
      supervisor(PlenarioWeb.Endpoint, []),
      supervisor(Plenario.TableModelRegistry, []),
      supervisor(Plenario.ViewModelRegistry, []),
      supervisor(Plenario.Etl, []),
      worker(Plenario.Etl.Queue, [])
    ]

    etl_workers =
      Enum.map(1..@num_etl_workers, fn i ->
        worker(Plenario.Etl.Worker, [], id: String.to_atom("worker_#{i}"))
      end)

    children = children ++ etl_workers

    opts = [strategy: :one_for_one, name: Plenario.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    PlenarioWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
