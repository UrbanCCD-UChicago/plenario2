defmodule PlenarioEtl.Schemas.EtlJob do
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

  schema "etl_jobs" do
    field(:state, :string, default: "new")
    field(:started_on, :utc_datetime)
    field(:completed_on, :utc_datetime)
    field(:error_message, :string)

    belongs_to(:meta, Plenario.Schemas.Meta)
    has_many(:data_set_diffs, PlenarioEtl.Schemas.DataSetDiff)
  end
end
