use Mix.Config

import_config("test.exs")

config :plenario, Plenario.Repo,
  adapter: Ecto.Adapters.Postgres,
  password: ""
