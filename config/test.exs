use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :plenario2, Plenario2Web.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn, metadata: [:request_id]

# Configure your database
config :plenario2, Plenario2.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "password",
  database: "plenario2_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# Configure Guardian
config :plenario2, Plenario2Auth.Guardian,
  issuer: "Plenario",
  secret_key: "qwertyuiopASDFGHJKLzxcvbnm1234567890QWERTYUIOPasdfghjklZXCVBNM!@"

# Configure HTTP API
config :plenario2, :http, HTTP.Mock

# Configure worker settings
config :plenario2, Plenario2Etl,
  chunk_size: 100,
  pool_size: 10

# configure bamboo (email)
config :plenario2, Plenario2.Mailer, adapter: Bamboo.TestAdapter
