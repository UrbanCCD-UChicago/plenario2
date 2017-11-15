defmodule Plenario2.Core.Changesets.VirtualPointFieldChangesets do
  import Ecto.Changeset

  def create_from_loc(struct, params) do
    struct
    |> cast(params, [:location_field, :meta_id])
    |> validate_required([:location_field, :meta_id])
    |> cast_assoc(:meta)
    |> _set_name_loc()
  end

  def create_long_lat(struct, params) do
    struct
    |> cast(params, [:longitude_field, :latitude_field, :meta_id])
    |> validate_required([:longitude_field, :latitude_field, :meta_id])
    |> cast_assoc(:meta)
    |> _set_name_long_lat()
  end

  ##
  # operations

  defp _set_name_long_lat(changeset) do
    long = get_field(changeset, :longitude_field)
    lat = get_field(changeset, :latitude_field)

    changeset |> put_change(:name, "_meta_point_#{long}_#{lat}")
  end

  defp _set_name_loc(changeset) do
    loc = get_field(changeset, :location_field)

    changeset |> put_change(:name, "_meta_point_#{loc}")
  end
end
