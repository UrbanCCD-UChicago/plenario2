defmodule Plenario.Mixfile do
  use Mix.Project

  @version "0.13.0"

  def project do
    [
      app: :plenario,
      version: @version,
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
      extra_applications: [
        :bamboo,
        :bamboo_smtp,
        :briefly,
        :logger,
        :runtime_tools,
        :sentry
      ]
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
      # phoenix deps
      {:phoenix, "~> 1.3.2"},
      {:phoenix_pubsub, "~> 1.0"},
      {:phoenix_ecto, "~> 3.2"},
      {:postgrex, ">= 0.13.5"},
      {:phoenix_html, "~> 2.10"},
      {:phoenix_live_reload, "~> 1.0", only: :dev},
      {:gettext, "~> 0.15.0"},
      {:cowboy, "~> 1.0"},

      # database utils
      {:geo_postgis, "~> 1.0"},
      {:ecto_state_machine, "~> 0.3.0"},
      {:scrivener, "~> 2.5"},
      {:scrivener_ecto, "~> 1.3"},

      # hashing and auth utils
      {:comeonin, "~> 4.0"},
      {:bcrypt_elixir, "~> 1.0"},
      {:guardian, "~> 1.0"},
      {:canary, "~> 1.1"},
      {:canada, "~> 1.0"},

      # http and api utils
      {:cors_plug, "~> 1.5"},

      # Parsing libraries
      {:csv, "~> 2.0"},          # csv
      {:poison, "~> 3.1"},       # json
      {:sweet_xml, "~> 0.6.5"},  # xml

      # etc utils
      {:timex, "~> 3.2.1"},
      {:httpoison, "~> 0.13.0"},
      {:slugify, "~> 1.1"},
      {:briefly, "~> 0.3"},

      # Job scheduler
      {:quantum, "~> 2.2"},

      # Emailing libraries
      {:bamboo, "~> 0.8"},
      {:bamboo_smtp, "~> 1.4.0"},

      # Aws client libraries
      {:ex_aws, "~> 2.0"},
      {:ex_aws_s3, "~> 2.0"},

      # testing utils
      {:excoveralls, "~> 0.7", only: :test},
      {:mock, "~> 0.3.1", only: :test},
      {:bypass, "~> 0.8.1", only: :test},

      # releases
      {:distillery, "~> 1.5"},

      # job workflow
      {:gen_stage, "~> 0.14.0"},

      # Specification for composable modules between elixir web applications.
      # Provides conveniences over web connections to allow for easy handling.
      #
      # Apache 2.0
      #
      # TODO(heyzoos) This is set to `1.5.0` because version `1.6.0` of plug
      # has been causing this error with sentry.
      #
      # https://github.com/getsentry/sentry-elixir/issues/275
      #
      # Hopefully this will get resolved in future versions of plug or sentry.
      {:plug, "~> 1.5.0", override: true},

      # Real time error tracking platform.
      #
      # BSD 3-Clause "New" or "Revised" License
      {:sentry, "~> 6.3.0"}
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
