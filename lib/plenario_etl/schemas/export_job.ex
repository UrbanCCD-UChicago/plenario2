defmodule PlenarioEtl.Schemas.ExportJob do
  @moduledoc """
  Defines the schema for ExportJob.

  - `query` is the string version of the query used to generate the output
  - `export_path` is the path to the exported file on AWS S3
  - `export_ttl` is the TTL date for the exported file
  """

  use Ecto.Schema

  use EctoStateMachine,
    states: [:new, :started, :erred, :completed],
    events: [
      [
        name: :mark_started,
        from: [:new],
        to: :started
      ], [
        name: :mark_erred,
        from: [:started],
        to: :erred
      ], [
        name: :mark_completed,
        from: [:started],
        to: :completed
      ]
    ]

  schema "export_jobs" do
    field(:query, :string)
    field(:export_path, :string)
    field(:export_ttl, :utc_datetime)

    # :inserted_at & :updated_at
    timestamps(type: :utc_datetime)
    field(:state, :string, default: "new")
    field(:error_message, :string)

    belongs_to(:user, Plenario.Schemas.User)
    belongs_to(:meta, Plenario.Schemas.Meta)
  end
end
