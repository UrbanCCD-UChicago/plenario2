defmodule Plenario2.Changesets.VirtualPointFieldChangesets do
  @moduledoc """
  This module provides functions for creating changesets for
  VirtualPointField structs.
  """

  import Ecto.Changeset

  alias Plenario2.Actions.{MetaActions, DataSetFieldActions}
  alias Plenario2.Schemas.VirtualPointField

  def new_from_loc() do
    %VirtualPointField{}
    |> cast(%{}, [:location_field, :meta_id])
  end

  @doc """
  Creates a changeset for inserting a new VirtualPointField into the database
  that is sourced from a single text field.
  """
  @spec create_from_loc(params :: %{meta_id: integer, location_field: String.t()}) ::
          Ecto.Changeset.t()
  def create_from_loc(params) do
    %VirtualPointField{}
    |> cast(params, [:location_field, :meta_id])
    |> validate_required([:location_field, :meta_id])
    |> validate_loc()
    |> cast_assoc(:meta)
    |> set_name_loc()
  end

  def new_from_long_lat() do
    %VirtualPointField{}
    |> cast(%{}, [:longitude_field, :latitude_field, :meta_id])
  end

  @doc """
  Creates a changeset for inserting a new VirtualPointField into the database
  that is sourced from a longitude field and latitude field.
  """
  @spec create_from_long_lat(
          params :: %{meta_id: integer, longitude_field: String.t(), latitude_field: String.t()}
        ) :: Ecto.Changeset.t()
  def create_from_long_lat(params) do
    %VirtualPointField{}
    |> cast(params, [:longitude_field, :latitude_field, :meta_id])
    |> validate_required([:longitude_field, :latitude_field, :meta_id])
    |> validate_long_lat()
    |> cast_assoc(:meta)
    |> set_name_long_lat()
  end

  defp set_name_long_lat(changeset) do
    long = get_field(changeset, :longitude_field)
    lat = get_field(changeset, :latitude_field)

    changeset |> put_change(:name, "_meta_point_#{long}_#{lat}")
  end

  defp set_name_loc(changeset) do
    loc = get_field(changeset, :location_field)

    changeset |> put_change(:name, "_meta_point_#{loc}")
  end

  defp validate_loc(changeset) do
    meta_id = get_field(changeset, :meta_id)
    loc = get_field(changeset, :location_field)

    meta = MetaActions.get(meta_id)
    fields = DataSetFieldActions.list_for_meta(meta)
    known_field_names = for f <- fields, do: f.name

    if Enum.member?(known_field_names, loc) do
      changeset
    else
      changeset
      |> add_error(:fields, "Field names must exist as registered fields of the data set")
    end
  end

  defp validate_long_lat(changeset) do
    meta_id = get_field(changeset, :meta_id)
    long = get_field(changeset, :longitude_field)
    lat = get_field(changeset, :latitude_field)

    field_names = [long, lat]

    meta = MetaActions.get(meta_id)
    fields = DataSetFieldActions.list_for_meta(meta)
    known_field_names = for f <- fields, do: f.name

    is_subset = field_names |> Enum.all?(fn name -> Enum.member?(known_field_names, name) end)

    if is_subset do
      changeset
    else
      changeset
      |> add_error(:fields, "Field names must exist as registered fields of the data set")
    end
  end
end
