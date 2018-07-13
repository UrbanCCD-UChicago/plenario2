use Mix.Config

# In this file, we keep production configuration that
# you'll likely want to automate and keep away from
# your version control system.
#
# You should document the content of this
# file or create a script for recreating it, since it's
# kept out of version control and might be hard to recover
# or recreate for your teammates (or yourself later on).
config :plenario, PlenarioWeb.Endpoint,
  secret_key_base: "ha8doE4RvtTitmYwgYiI0mmPbyzx36wsSDESjP5gRFejrTxvaaBBKqxJV14nBfLm"


# Configure your database
config :plenario, Plenario.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "plenario",
  database: "plenario_prod",
  pool_size: 15


# Configure Guardian
config :plenario, PlenarioAuth.Guardian,
  issuer: "Plenario",
  secret_key: "BNQZaX1ghM+BpLxAeA8A4nlohbabU29Yrcrf1OQqDBn9cl14IfKZHBt8JyCrz91w"


# configure bamboo (email)
config :plenario, PlenarioMailer,
  adapter: Bamboo.SMTPAdapter,
  server: "email-smtp.us-east-1.amazonaws.com",
  hostname: "uchicago.edu",
  port: 587,
  username: "AKIAJD55FDBLK6SQJKLA",
  password: "AuTdkhlVUC14TzfKTo4zc+4fNc2Mj5nGST1b6wI1AxmH",
  tls: :always,
  allowed_tls_versions: [:tlsv1, :"tlsv1.1", :"tlsv1.2"],
  ssl: false,
  retries: 1


# configure sentry
config :sentry,
  dsn: "https://d1f0adc901084a888bb53605090715c5:818883cc162d4029a974400d4c0118b5@sentry.io/289609",
  environment_name: :prod,
  included_environments: [:prod],
  enable_source_code_context: true,
  root_source_code_path: File.cwd!
