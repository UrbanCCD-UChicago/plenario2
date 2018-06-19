use Mix.Config

# Store the environment atom for situations where the `Mix` module is
# unavailable such as production or when compiling releases through
# Exrm or Distillery. Any code looking to use the environment atom should
# do so through `Application.get_env(:plenario, :env)`
config :plenario, env: Mix.env()

# Configure the database and application repo
config :plenario, Plenario.Repo,
  types: Plenario.PostGisTypes,
  extensions: Plenario.Extensions.TsRange,
  handshake_timeout: 120000,
  pool_timeout: 120000,
  timeout: 120000

config :plenario, ecto_repos: [Plenario.Repo]


# Configures the endpoint
config :plenario, PlenarioWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "jCp/RnOfjaRob73dORfNI9QvsP5719peAhXoo6SP2N41Kw+5Ofq9N0Zu6cyzqGI4",
  render_errors: [view: PlenarioWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Plenario.PubSub, adapter: Phoenix.PubSub.PG2]


# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: :all


# Configure the exporter
config :plenario, :s3_export_ttl, days: 5
config :plenario, :s3_export_bucket, "plenario-exports"


# configure quantum scheduler
config :plenario, :refresh_offest, minutes: -1

config :plenario, PlenarioEtl.Scheduler,
  global: true,
  jobs: [
    # run the find refreshable metas every minute (offset is 1 minute above)
    {"* * * * *", {PlenarioEtl.ScheduledJobs, :refresh_datasets, []}}
  ]

config :plenario, PlenarioAot.AotScheduler,
  global: true,
  jobs: [
    {"*/5 * * * *", {PlenarioAot.AotScheduler, :import_aot_data, []}}
  ]

config :plenario, PlenarioAot,
  pool_size: 10


# configure canary
config :canary,
  repo: Plenario.Repo,
  unauthorized_handler: {PlenarioAuth.ErrorHandler, :handle_unauthorized},
  not_found_handler: {PlenarioAuth.ErrorHandler, :handle_not_found}


# configure bamboo (email)
config :plenario, PlenarioMailer, adapter: Bamboo.LocalAdapter
config :plenario, :email_sender, "plenario@uchicago.edu"
config :plenario, :email_subject, "Plenario Notification"

config :cors_plug,
  max_age: 300, # five minutes
  methods: ["GET", "HEAD", "OPTIONS"]

# configure sentry
config :sentry,
  dsn: "https://public:secret@app.getsentry.com/1",
  environment_name: :prod,
  included_environments: [:prod],
  enable_source_code_context: true,
  root_source_code_path: File.cwd!


# configure aws client
config :ex_aws,
  secret_access_key: [{:system, "AWS_SECRET_ACCESS_KEY"}, :instance_role],
  access_key_id: [{:system, "AWS_ACCESS_KEY_ID"}, :instance_role]


# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
