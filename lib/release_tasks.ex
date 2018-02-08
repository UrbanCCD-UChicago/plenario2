defmodule Plenario.ReleaseTasks do
  @moduledoc """
  This module defines functions that can be wrapped using the
  Shell Script API so that certain operations can be executed
  from a release.

  For example, to run migrations from a release:

    $ /path/to/release/bin/plenario migrate

  Based on https://github.com/bitwalker/distillery/blob/master/docs/Running%20Migrations.md
  """

  @start_apps [
    :crypto,
    :ssl,
    :postgrex,
    :ecto
  ]

  defp myapp, do: :plenario

  def migrate do
    prepare()
    Enum.each(repos(), &run_migrations_for/1)
  end

  defp repos, do: Application.get_env(myapp(), :ecto_repos, [])

  defp migrations_path(repo), do: priv_path_for(repo, "migrations")

  defp priv_dir(app), do: "#{:code.priv_dir(app)}"

  defp prepare do
    me = myapp()

    IO.puts "Loading #{me}.."
    # Load the code for myapp, but don't start it
    :ok = Application.load(me)

    IO.puts "Starting dependencies.."
    # Start apps necessary for executing migrations
    Enum.each(@start_apps, &Application.ensure_all_started/1)

    # Start the Repo(s) for myapp
    IO.puts "Starting repos.."
    Enum.each(repos(), &(&1.start_link(pool_size: 1)))
  end

  defp run_migrations_for(repo) do
    app = Keyword.get(repo.config, :otp_app)
    IO.puts "Running migrations for #{app}"

    Ecto.Migrator.run(repo, migrations_path(repo), :up, all: true)
  end

  defp priv_path_for(repo, filename) do
    app = Keyword.get(repo.config, :otp_app)
    repo_underscore =
      repo
      |> Module.split()
      |> List.last()
      |> Macro.underscore()

    Path.join([priv_dir(app), repo_underscore, filename])
  end
end
