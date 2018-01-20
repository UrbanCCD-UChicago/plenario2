# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Configure the database
config :plenario2, Plenario2.Repo, types: Plenario2.PostGISTypes

# General application configuration
config :plenario2, ecto_repos: [Plenario2.Repo]

# Configures the endpoint
config :plenario2, Plenario2Web.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "jCp/RnOfjaRob73dORfNI9QvsP5719peAhXoo6SP2N41Kw+5Ofq9N0Zu6cyzqGI4",
  render_errors: [view: Plenario2Web.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Plenario2.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Configure s3 buckets
config :plenario2, :s3_export_bucket, "plenario_exports_#{Mix.env()}"

config :plenario2, :s3_export_ttl, days: 5

# configure quantum scheduler

config :plenario2, :refresh_offest, minutes: 1

config :plenario2, Plenario2.Scheduler,
  global: true,
  jobs: [
    # run the find refreshable metas every minute (offset is 1 minute above)
    {"* * * * *", {Plenario2.Etl.ScheduledJobs, :find_refreshable_metas, []}}
  ]

# configure canary
config :canary,
  repo: Plenario2.Repo,
  unauthorized_handler: {Plenario2Auth.ErrorHandler, :handle_unauthorized},
  not_found_handler: {Plenario2Auth.ErrorHandler, :handle_not_found}

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"

# configure bamboo (email)
config :plenario2, Plenario2.Mailer,
  adapter: Bamboo.LocalAdapter
