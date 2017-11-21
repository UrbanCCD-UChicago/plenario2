defmodule Plenario2.Core.Schemas.Meta do
  use Ecto.Schema

  schema "metas" do
    field(:name, :string)
    field(:slug, :string)
    field(:state, :string)
    field(:description, :string)
    field(:attribution, :string)
    field(:source_url, :string)
    field(:source_type, :string)
    field(:first_import, :utc_datetime)
    field(:latest_import, :utc_datetime)
    field(:refresh_rate, :string)
    field(:refresh_interval, :integer)
    field(:refresh_starts_on, :utc_datetime)
    field(:refresh_ends_on, :utc_datetime)
    field(:next_refresh, :utc_datetime)
    field(:srid, :integer)
    field(:bbox, Geo.Polygon)
    field(:timezone, :string)
    field(:timerange, :map)

    timestamps()

    belongs_to(:user, Plenario2.Core.Schemas.User)
    has_many(:data_set_fields, Plenario2.Core.Schemas.DataSetField)
    has_many(:data_set_constraints, Plenario2.Core.Schemas.DataSetConstraint)
    has_many(:virtual_date_fields, Plenario2.Core.Schemas.VirtualDateField)
    has_many(:virtual_point_fields, Plenario2.Core.Schemas.VirtualPointField)
    has_many(:etl_jobs, Plenario2.Core.Schemas.EtlJob)
    has_many(:data_set_diffs, Plenario2.Core.Schemas.DataSetDiff)
    has_many(:export_jobs, Plenario2.Core.Schemas.ExportJob)
  end

  ##
  # schema functions

  def get_dataset_table_name(meta) do
    meta.name
    |> String.split(~r/\s/, trim: true)
    |> Enum.map(&(String.downcase(&1)))
    |> Enum.join("_")
  end
end
