defmodule Plenario2.Schemas.Meta do
  use Ecto.Schema
  use EctoStateMachine,
    states: [:new, :needs_approval, :ready, :erred],
    events: [
      [
        name: :submit_for_approval,
        from: [:new],
        to: :needs_approval
      ], [
        name: :approve,
        from: [:needs_approval],
        to: :ready
      ], [
        name: :disapprove,
        from: [:needs_approval],
        to: :new
      ], [
        name: :mark_erred,
        from: [:ready],
        to: :erred
      ], [
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

    belongs_to(:user, Plenario2Auth.User)
    has_many(:data_set_fields, Plenario2.Schemas.DataSetField)
    has_many(:data_set_constraints, Plenario2.Schemas.DataSetConstraint)
    has_many(:virtual_date_fields, Plenario2.Schemas.VirtualDateField)
    has_many(:virtual_point_fields, Plenario2.Schemas.VirtualPointField)
    has_many(:etl_jobs, Plenario2.Schemas.EtlJob)
    has_many(:data_set_diffs, Plenario2.Schemas.DataSetDiff)
    has_many(:export_jobs, Plenario2.Schemas.ExportJob)
  end

  ##
  # schema functions

  def get_data_set_table_name(meta) do
    meta.name
    |> String.split(~r/\s/, trim: true)
    |> Enum.map(&String.downcase/1)
    |> Enum.join("_")
  end
end
