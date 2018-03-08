defmodule PlenarioEtl.Schemas.EtlJob do
  @moduledoc """
  Defines the schema for EtlJob.

  - `state` is the state of the job
  - `started_on` is the start timestamp of the job
  - `completed_on` is the ending timetamp of the job
  - `error_message` is the error trace if an error occurred
  """

  use Ecto.Schema
  use EctoStateMachine,
    states: [:new, :running, :erred, :partial_success, :succeeded],
    events: [
      [
        name: :start,
        from: [:new],
        to: :running
      ], [
        name: :mark_erred,
        from: [:running],
        to: :erred
      ], [
        name: :mark_succeeded,
        from: [:running],
        to: :succeeded
      ], [
        name: :mark_partial_success,
        from: [:running],
        to: :partial_success
      ]
    ]

  schema "etl_jobs" do
    field(:state, :string, default: "new")
    field(:started_on, :utc_datetime)
    field(:completed_on, :utc_datetime)
    field(:error_message, :string)

    timestamps(type: :utc_datetime)

    belongs_to(:meta, Plenario.Schemas.Meta)
    has_many(:data_set_diffs, PlenarioEtl.Schemas.DataSetDiff)
  end
end
