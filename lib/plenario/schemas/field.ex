defmodule Plenario.Field do
  use Ecto.Schema

  import Ecto.Changeset

  import Plenario.SchemaUtils

  alias Ecto.Changeset

  alias Plenario.{
    DataSet,
    Field,
    VirtualDate,
    VirtualPoint
  }

  schema "fields" do
    field :name, :string
    field :col_name, :string
    field :type, :string
    field :description, :string, default: nil
    belongs_to :data_set, DataSet

    # reverse relationships
    has_many :virtual_yrs, VirtualDate, foreign_key: :yr_field_id
    has_many :virtual_mos, VirtualDate, foreign_key: :mo_field_id
    has_many :virtual_days, VirtualDate, foreign_key: :day_field_id
    has_many :virtual_hrs, VirtualDate, foreign_key: :hr_field_id
    has_many :virtual_mins, VirtualDate, foreign_key: :min_field_id
    has_many :virtual_secs, VirtualDate, foreign_key: :sec_field_id
    has_many :virtual_locs, VirtualPoint, foreign_key: :loc_field_id
    has_many :virtual_lons, VirtualPoint, foreign_key: :lon_field_id
    has_many :virtual_lats, VirtualPoint, foreign_key: :lat_field_id
  end

  defimpl Phoenix.HTML.Safe, for: Field, do: def to_iodata(field), do: field.name

  def type_choices, do: [Text: "text", Integer: "integer", Float: "float", Boolean: "boolean", Timestamp: "timestamp", JSON: "jsonb", Geometry: "geometry"]

  @attrs ~w|data_set_id name type description|a

  @reqd ~w|data_set_id name type|a

  @types ~w|text integer float boolean timestamp jsonb geometry|

  @doc false
  def changeset(field, attrs) do
    field
    |> cast(attrs, @attrs)
    |> validate_required(@reqd)
    # validators
    |> validate_inclusion(:type, @types)
    |> validate_data_set_state()
    # putting stuff
    |> put_col_name()
    # constraint capture
    |> foreign_key_constraint(:data_set_id)
    |> unique_constraint(:name, name: :field_ds_uniq)
  end

  defp put_col_name(%Changeset{changes: %{name: name}} = changeset), do: put_change(changeset, :col_name, postgresify(name))
  defp put_col_name(c), do: c
end
