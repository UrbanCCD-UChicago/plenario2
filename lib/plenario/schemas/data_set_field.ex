defmodule Plenario.Schemas.DataSetField do
  @moduledoc """
  Defines the schema for DataSetFields
  """

  use Ecto.Schema

  @type_values [
    "text",
    "integer",
    "float",
    "boolean",
    "timestamptz",
    "geometry",
    "jsonb"
  ]

  @type_choices [
    Text: "text",
    Integer: "integer",
    Decimal: "float",
    "True/False": "boolean",
    Date: "timestamptz",
    "Raw GIS Field": "geometry",
    JSON: "jsonb"
  ]

  schema "data_set_fields" do
    field :name, :string
    field :type, :string

    timestamps(type: :utc_datetime)

    belongs_to :meta, Plenario.Schemas.Meta

    has_many :virtual_years, Plenario.Schemas.VirtualDateField, foreign_key: :year_field_id
    has_many :virtual_months, Plenario.Schemas.VirtualDateField, foreign_key: :month_field_id
    has_many :virtual_days, Plenario.Schemas.VirtualDateField, foreign_key: :day_field_id
    has_many :virtual_hours, Plenario.Schemas.VirtualDateField, foreign_key: :hour_field_id
    has_many :virtual_minutes, Plenario.Schemas.VirtualDateField, foreign_key: :minute_field_id
    has_many :virtual_seconds, Plenario.Schemas.VirtualDateField, foreign_key: :second_field_id

    has_many :virtual_lats, Plenario.Schemas.VirtualPointField, foreign_key: :lat_field_id
    has_many :virtual_lons, Plenario.Schemas.VirtualPointField, foreign_key: :lon_field_id
    has_many :virtual_locs, Plenario.Schemas.VirtualPointField, foreign_key: :loc_field_id
  end

  @doc """
  Returns a list of acceptible values for :type
  """
  @spec get_type_values() :: list(String.t())
  def get_type_values(), do: @type_values

  @doc """
  Returns a keyword list of mappings of friendly names and acceptible
  values for :type
  """
  @spec get_type_choices() :: Keyword.t()
  def get_type_choices(), do: @type_choices
end
