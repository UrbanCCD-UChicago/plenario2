defmodule Plenario.Application do
  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      supervisor(Plenario.Repo, []),

      # Start the endpoint when the application starts
      supervisor(PlenarioWeb.Endpoint, []),
      # Start your own worker by calling: Plenario.Worker.start_link(arg1, arg2, arg3)
      # worker(Plenario.Worker, [arg1, arg2, arg3]),

      # Start the quantum scheduler
      supervisor(PlenarioEtl.Scheduler, []),

      # Start the model registry
      supervisor(Plenario.ModelRegistry, [%{}]),

      # Start the etl supervisor
      supervisor(PlenarioEtl.Application, [])
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Plenario.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    PlenarioWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
