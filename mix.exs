defmodule Plenario.Mixfile do
  use Mix.Project

  def project do
    [
      app: :plenario,
      version: "0.20.2",
      elixir: "~> 1.6",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  def application do
    extras =
      if Mix.env() == :prod do
        [:sentry, :logger, :runtime_tools]
      else
        [:logger, :runtime_tools]
      end

    [
      mod: {Plenario.Application, []},
      extra_applications: extras
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # phoenix stuff
      {:phoenix, "~> 1.4"},
      {:phoenix_pubsub, "~> 1.1"},
      {:phoenix_ecto, "~> 4.0"},
      {:ecto_sql, "~> 3.0"},
      {:ecto, "~> 3.0", override: true},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 2.11"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:gettext, "~> 0.11"},
      {:plug_cowboy, "~> 2.0"},

      # database libs
      {:geo_postgis, "~> 1.0"},

      # auth
      {:comeonin, "~> 4.0"},
      {:bcrypt_elixir, "~> 1.0"},
      {:guardian, "~> 1.0"},
      {:canary, "~> 1.1"},
      {:canada, "~> 1.0"},

      # general utils
      {:timex, "~> 3.4"},
      {:simple_slug, ">= 0.1.0"},
      {:httpoison, "~> 0.13.0", override: true},
      {:jason, "~> 1.0"},
      {:poison, "~> 3.0", override: true},
      {:csv, "~> 2.0"},
      {:socrata, ">= 1.0.0"},

      # workflow utils
      {:gen_stage, "~> 0.14.0"},
      {:quantum, "~> 2.2"},

      # testing utils
      {:mock, "~> 0.3.2", only: :test},

      # releases
      {:distillery, "~> 2.0"},
      {:sentry, "~> 6.4"}
    ]
  end

  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
