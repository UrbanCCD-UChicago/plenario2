defmodule Plenario.Schemas.Meta do
  use Ecto.Schema

  use EctoStateMachine,
    states: [:new, :needs_approval, :ready, :erred],
    events: [
      [
        name: :submit_for_approval,
        from: [:new],
        to: :needs_approval
      ],
      [
        name: :approve,
        from: [:needs_approval],
        to: :ready
      ],
      [
        name: :disapprove,
        from: [:needs_approval],
        to: :new
      ],
      [
        name: :mark_erred,
        from: [:ready],
        to: :erred
      ],
      [
        name: :mark_fixed,
        from: [:erred],
        to: :ready
      ]
    ]

  schema "metas" do
    field(:name, :string)
    field(:slug, :string)
    field(:state, :string, default: "new")
    field(:description, :string)
    field(:attribution, :string)
    field(:source_url, :string)
    field(:source_type, :string)
    field(:first_import, :utc_datetime)
    field(:latest_import, :utc_datetime)
    field(:refresh_rate, :string)
    field(:refresh_interval, :integer)
    field(:refresh_starts_on, :date)
    field(:refresh_ends_on, :date)
    field(:next_refresh, :utc_datetime)
    field(:srid, :integer)
    field(:bbox, Geo.Polygon)
    field(:timezone, :string)
    field(:timerange, :map)

    timestamps()

    belongs_to(:user, PlenarioAuth.User)
    has_many(:data_set_fields, Plenario.Schemas.DataSetField)
    has_many(:data_set_constraints, Plenario.Schemas.DataSetConstraint)
    has_many(:virtual_date_fields, Plenario.Schemas.VirtualDateField)
    has_many(:virtual_point_fields, Plenario.Schemas.VirtualPointField)
    has_many(:etl_jobs, Plenario.Schemas.EtlJob)
    has_many(:data_set_diffs, Plenario.Schemas.DataSetDiff)
    has_many(:export_jobs, Plenario.Schemas.ExportJob)
    has_many(:admin_user_notes, Plenario.Schemas.AdminUserNote)
  end

  @refresh_rate_values [
    nil,
    "minutes",
    "hours",
    "days",
    "weeks",
    "months",
    "years"
  ]

  @refresh_rate_choices [
    "Don't Refresh": nil,
    Minutes: "minutes",
    Hours: "hours",
    Days: "days",
    Weeks: "weeks",
    Months: "months",
    Years: "years"
  ]

  def get_refresh_rate_values(), do: @refresh_rate_values

  def get_refresh_rate_choices(), do: @refresh_rate_choices
end
