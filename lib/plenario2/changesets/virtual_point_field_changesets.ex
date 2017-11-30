defmodule Plenario2.Changesets.VirtualPointFieldChangesets do
  import Ecto.Changeset
  alias Plenario2.Actions.{MetaActions, DataSetFieldActions}

  def create_from_loc(struct, params) do
    struct
    |> cast(params, [:location_field, :meta_id])
    |> validate_required([:location_field, :meta_id])
    |> validate_loc()
    |> cast_assoc(:meta)
    |> set_name_loc()
  end

  def create_from_long_lat(struct, params) do
    struct
    |> cast(params, [:longitude_field, :latitude_field, :meta_id])
    |> validate_required([:longitude_field, :latitude_field, :meta_id])
    |> validate_long_lat()
    |> cast_assoc(:meta)
    |> set_name_long_lat()
  end

  ##
  # operations

  defp set_name_long_lat(changeset) do
    long = get_field(changeset, :longitude_field)
    lat = get_field(changeset, :latitude_field)

    changeset |> put_change(:name, "_meta_point_#{long}_#{lat}")
  end

  defp set_name_loc(changeset) do
    loc = get_field(changeset, :location_field)

    changeset |> put_change(:name, "_meta_point_#{loc}")
  end

  ##
  # validation

  defp validate_loc(changeset) do
    meta_id = get_field(changeset, :meta_id)
    loc = get_field(changeset, :location_field)

    meta = MetaActions.get_from_id(meta_id)
    fields = DataSetFieldActions.list_for_meta(meta)
    known_field_names = for f <- fields, do: f.name
    if Enum.member?(known_field_names, loc) do
      changeset
    else
      changeset |> add_error(:fields, "Field names must exist as registered fields of the dataset")
    end
  end

  defp validate_long_lat(changeset) do
    meta_id = get_field(changeset, :meta_id)
    long = get_field(changeset, :longitude_field)
    lat = get_field(changeset, :latitude_field)

    field_names = [long, lat]

    meta = MetaActions.get_from_id(meta_id)
    fields = DataSetFieldActions.list_for_meta(meta)
    known_field_names = for f <- fields, do: f.name

    is_subset = field_names |> Enum.all?(fn (name) -> Enum.member?(known_field_names, name) end)
    if is_subset do
      changeset
    else
      changeset |> add_error(:fields, "Field names must exist as registered fields of the dataset")
    end
  end
end
