defmodule Plenario2.Core.Changesets.VirtualPointFieldChangeset do
  import Ecto.Changeset

  def create(struct, params) do
    struct
    |> cast(params, [:longitude_field, :latitude_field, :location_field, :meta_id])
    |> validate_required([:meta_id])
    |> _validate_longlat_or_loc()
    |> cast_assoc(:meta)
    |> _set_name()
  end

  ##
  # operations

  defp _set_name(changeset) do
    loc = get_field(changeset, :location_field)
    long = get_field(changeset, :longitude_field)
    lat = get_field(changeset, :longitude_field)

    name =
      cond do
        loc -> "_meta_point_#{loc}"
        long and lat -> "_meta_point_#{long}_#{lat}"
      end

    changeset |> put_change(:name, name)
  end

  ##
  # validation

  defp _validate_longlat_or_loc(changeset) do
    loc = get_field(changeset, :location_field)
    if loc do
      changeset
      |> put_change(:longitude_field, nil)
      |> put_change(:latitude_field, nil)
    else
      long = get_field(changeset, :longitude_field)
      lat = get_field(changeset, :latitude_field)
      if long != nil and lat != nil do
        changeset
      else
        changeset
        |> add_error(:longitude_field, "Missing longitude and latitude")
        |> add_error(:latitude_field, "Missing longitude and latitude")
      end
    end
  end
end
