defmodule Plenario.VirtualPoint do
  use Ecto.Schema

  import Ecto.Changeset

  import Plenario.SchemaUtils

  alias Plenario.{
    DataSet,
    Field,
    VirtualPoint
  }

  schema "virtual_points" do
    field :col_name, :string
    belongs_to :data_set, DataSet
    belongs_to :loc_field, Field
    belongs_to :lon_field, Field
    belongs_to :lat_field, Field
  end

  defimpl Phoenix.HTML.Safe, for: VirtualPoint, do: def to_iodata(point), do: point.col_name

  @attrs ~w|data_set_id loc_field_id lon_field_id lat_field_id|a

  @reqd ~w|data_set_id|a

  @loc_lon_lat_error "either location or longitude and latitude must be set -- they are mutually exclusive"

  @doc false
  def changeset(virtual_point, attrs) do
    virtual_point
    |> cast(attrs, @attrs)
    |> validate_required(@reqd)
    |> validate_loc_lon_lat()
    |> validate_data_set_state()
    |> put_col_name()
    |> unique_constraint(:col_name)
    |> foreign_key_constraint(:data_set_id)
    |> foreign_key_constraint(:loc_field_id)
    |> foreign_key_constraint(:lon_field_id)
    |> foreign_key_constraint(:lat_field_id)
  end

  # validates loc/{lon, lat} mutual exclusivity

  defp validate_loc_lon_lat(changeset) do
    loc = get_field(changeset, :loc_field_id)
    lon = get_field(changeset, :lon_field_id)
    lat = get_field(changeset, :lat_field_id)

    do_validate_loc_lon_lat(changeset, loc, lon, lat)
  end

  defp do_validate_loc_lon_lat(changeset, loc, nil, nil) when not is_nil(loc), do: changeset
  defp do_validate_loc_lon_lat(changeset, nil, lon, lat) when not is_nil(lon) and not is_nil(lat), do: changeset
  defp do_validate_loc_lon_lat(changeset, _, _, _), do: add_error(changeset, :loc_field_id, @loc_lon_lat_error) |> add_error(:lon_field_id, @loc_lon_lat_error) |> add_error(:lat_field_id, @loc_lon_lat_error)

  # adds auto generated field

  defp put_col_name(changeset) do
    ds = get_field(changeset, :data_set_id)
    loc = get_field(changeset, :loc_field_id)
    lon = get_field(changeset, :lon_field_id)
    lat = get_field(changeset, :lat_field_id)

    do_put_col_name(changeset, ds, loc, lon, lat)
  end

  defp do_put_col_name(changeset, ds, loc, nil, nil) when not is_nil(loc),
    do: put_change(changeset, :col_name, postgresify("vp #{ds} #{loc}"))

  defp do_put_col_name(changeset, ds, nil, lon, lat) when not is_nil(lon) and not is_nil(lat),
    do: put_change(changeset, :col_name, postgresify("vp #{ds} #{lon} #{lat}"))

  defp do_put_col_name(changeset, _, _, _, _), do: changeset
end
