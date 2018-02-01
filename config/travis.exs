use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :plenario, PlenarioWeb.Endpoint,
  http: [port: 4001],
  server: false


# Print only warnings and errors during test
config :logger, level: :warn


# Configure your database
config :plenario, Plenario.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "",
  database: "plenario_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox


# Configure Guardian
config :plenario, PlenarioAuth.Guardian,
  issuer: "Plenario",
  secret_key: "qwertyuiopASDFGHJKLzxcvbnm1234567890QWERTYUIOPasdfghjklZXCVBNM!@"
