defmodule Plenario.Mixfile do
  use Mix.Project

  def project do
    [
      app: :plenario,
      version: "0.2.14",
      elixir: "~> 1.6",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Plenario.Application, []},
      extra_applications: [:logger, :runtime_tools, :bamboo, :bamboo_smtp, :sentry]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.3.2"},
      {:phoenix_pubsub, "~> 1.0"},
      {:phoenix_ecto, "~> 3.2"},
      {:postgrex, ">= 0.13.5"},
      {:phoenix_html, "~> 2.10"},
      {:phoenix_live_reload, "~> 1.0", only: :dev},
      {:gettext, "~> 0.15.0"},
      {:cowboy, "~> 1.0"},
      {:geo_postgis, "~> 1.0"},
      {:comeonin, "~> 4.0"},
      {:bcrypt_elixir, "~> 1.0"},
      {:excoveralls, "~> 0.7", only: :test},
      {:timex, "~> 3.2.1"},
      {:httpoison, "~> 0.13.0"},
      {:mock, "~> 0.3.1", only: :test},
      {:quantum, "~> 2.2.5"},
      {:guardian, "~> 1.0"},
      {:ecto_state_machine, "~> 0.3.0"},
      {:canary, "~> 1.1"},
      {:canada, "~> 1.0"},
      {:distillery, "~> 1.5"},
      {:slugify, "~> 1.1"},
      {:bamboo, "~> 0.8"},
      {:bamboo_smtp, "~> 1.4.0"},
      {:sentry, "~> 6.1.0"},

      # Parsing libraries
      {:csv, "~> 2.0"},          # csv
      {:poison, "~> 3.1"},       # json
      {:sweet_xml, "~> 0.6.5"},  # xml

      # Aws client libraries
      {:ex_aws, "~> 2.0"},
      {:ex_aws_s3, "~> 2.0"},
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
