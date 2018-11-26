use Mix.Config

config :plenario, env: Mix.env()

# Configure your database
config :plenario, Plenario.Repo,
  username: "postgres",
  password: "password",
  database: "plenario_#{Mix.env()}",
  hostname: "localhost",
  pool_size: 10,
  types: Plenario.PostgresTypes,
  extensions: Plenario.Extensions.TsRange

config :plenario,
  ecto_repos: [Plenario.Repo]

# Configures the endpoint
config :plenario, PlenarioWeb.Endpoint,
  url: [
    host: "localhost"
  ],
  secret_key_base: "jCp/RnOfjaRob73dORfNI9QvsP5719peAhXoo6SP2N41Kw+5Ofq9N0Zu6cyzqGI4",
  render_errors: [
    view: PlenarioWeb.ErrorView,
    accepts: ~w(html json)
  ],
  pubsub: [
    name: Plenario.PubSub,
    adapter: Phoenix.PubSub.PG2
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# configures the etl workers
config :plenario, Plenario.Etl, num_workers: 3

# configures etl schedule
config :plenario, Plenario.Etl,
  global: true,
  jobs: [
    {"* * * * *", {Plenario.Etl, :import_data_sets, []}}
  ]

# Configures guardian implementation
config :plenario, Plenario.Auth.Guardian,
  issuer: "plenario",
  secret_key: "9vh18AVJKIOVaxAUzCK8Y0SAR4OvJ5zVEpolA8F+26YUYhklwR1JC5Tbh97vJu1X"

# Configures the repo usage for Canary
config :canary,
  repo: Plenario.Repo,
  unauthorized_handler: {PlenarioWeb.ErrorController, :handle_unauthorized},
  not_found_handler: {PlenarioWeb.ErrorController, :handle_not_found}

# Configures sentry error reporting
tags =
  case Application.spec(:plenario) do
    nil -> []
    spec -> spec
  end

config :sentry,
  dsn: "https://key@sentry.io/1",
  included_environments: [:prod],
  environment_name: Mix.env(),
  enable_source_code_context: true,
  root_source_code_path: File.cwd!,
  tags: Enum.into(tags, %{})


# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
