use Mix.Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with brunch.io to recompile .js and .css sources.
config :plenario, PlenarioWeb.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [
    npm: [
      "run",
      "watch",
      cd: Path.expand("../assets", __DIR__)
    ]
  ]


# Watch static and templates for browser reloading.
config :plenario, PlenarioWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r{priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$},
      ~r{priv/gettext/.*(po)$},
      ~r{lib/plenario_web/views/.*(ex)$},
      ~r{lib/plenario_web/templates/.*(eex)$}
    ]
  ]


# Do not include metadata nor timestamps in development logs
config :logger, :console, level: :debug


# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20


# Configure your database
config :plenario, Plenario.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "plenario_dev",
  hostname: "localhost",
  pool_size: 10


# Configure Guardian
config :plenario, PlenarioAuth.Guardian,
  issuer: "Plenario",
  secret_key: "qwertyuiopASDFGHJKLzxcvbnm1234567890QWERTYUIOPasdfghjklZXCVBNM!@"


# Configure worker settings
config :plenario, PlenarioEtl,
  chunk_size: 100,
  pool_size: 10
