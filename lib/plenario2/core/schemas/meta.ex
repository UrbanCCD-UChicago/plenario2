defmodule Plenario2.Core.Schemas.Meta do
  use Ecto.Schema

  schema "metas" do
    field :name,              :string
    field :slug,              :string
    field :state,             :string
    field :description,       :string
    field :attribution,       :string
    field :source_url,        :string
    field :source_type,       :string
    field :first_import,      :utc_datetime
    field :latest_import,     :utc_datetime
    field :refresh_rate,      :string
    field :refresh_interval,  :integer
    field :refresh_starts_on, :utc_datetime
    field :refresh_ends_on,   :utc_datetime
    field :srid,              :integer
    field :bbox,              Geo.Polygon
    field :timezone,          :string
    field :timerange,         :map

    timestamps()

    belongs_to  :user,                  Core.Schemas.User
    has_many    :data_set_fields,       Core.Schemas.DataSetField
    has_many    :data_set_constraints,  Core.Schemas.DataSetConstraint
    has_many    :virtual_date_fields,   Core.Schemas.VirtualDateField
    has_many    :virtual_point_fields,  Core.Schemas.VirtualPointField
    has_many    :etl_jobs,              Core.Schemas.EtlJob
    has_many    :data_set_diffs,        Core.Schemas.DataSetDiff
  end
end
