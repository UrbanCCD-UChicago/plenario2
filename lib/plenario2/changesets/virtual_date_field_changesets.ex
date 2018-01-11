defmodule Plenario2.Changesets.VirtualDateFieldChangesets do
  @moduledoc """
  This module provides functions for creating changesets for
  VirtualDateField structs.
  """

  import Ecto.Changeset

  alias Plenario2.Actions.{MetaActions, DataSetFieldActions}
  alias Plenario2.Schemas.VirtualDateField

  @typedoc """
  Verbose map of params for create
  """
  @type create_params :: %{
    meta_id: integer,
    year_field: String.t,
    month_field: String.t,
    day_field: String.t,
    hour_field: String.t,
    minute_field: String.t,
    second_field: String.t
  }

  @new_create_param_keys [
    :year_field,
    :month_field,
    :day_field,
    :hour_field,
    :minute_field,
    :second_field,
    :meta_id
  ]

  @doc """
  Creates a blank changeset for creating webforms
  """
  @spec new() :: Ecto.Changeset.t
  def new() do
    %VirtualDateField{}
    |> cast(%{}, @new_create_param_keys)
  end

  @doc """
  Creates a changeset for inserting a new VirtualDateField into the database.
  """
  @spec create(params :: create_params) :: Ecto.Changeset.t
  def create(params) do
    %VirtualDateField{}
    |> cast(params, @new_create_param_keys)
    |> validate_required([:year_field, :meta_id])
    |> validate_fields()
    |> cast_assoc(:meta)
    |> set_name()
  end

  @doc """
  Updates a VirtualDateField
  """
  @spec update(field :: VirtualDateField, params :: create_params) :: Ecto.Changeset.t
  def update(field, params) do
    field
    |> cast(params, @new_create_param_keys)
    |> validate_required([:year_field, :meta_id])
    |> validate_fields()
    |> cast_assoc(:meta)
    |> set_name()
    |> check_meta_state()
  end

  # Sets the name of the field as a function of the field names passed in
  defp set_name(changeset) do
    yr = get_field(changeset, :year_field)
    mo = get_field(changeset, :month_field)
    day = get_field(changeset, :day_field)
    hr = get_field(changeset, :hour_field)
    min = get_field(changeset, :minute_field)
    sec = get_field(changeset, :second_field)

    name =
      cond do
        yr != nil and mo != nil and day != nil and hr != nil and min != nil and sec != nil ->
          "_meta_date_#{yr}_#{mo}_#{day}_#{hr}_#{min}_#{sec}"

        yr != nil and mo != nil and day != nil and hr != nil and min != nil ->
          "_meta_date_#{yr}_#{mo}_#{day}_#{hr}_#{min}"

        yr != nil and mo != nil and day != nil and hr != nil ->
          "_meta_date_#{yr}_#{mo}_#{day}_#{hr}"

        yr != nil and mo != nil and day != nil ->
          "_meta_date_#{yr}_#{mo}_#{day}"

        yr != nil and mo != nil ->
          "_meta_date_#{yr}_#{mo}"

        yr != nil ->
          "_meta_date_#{yr}"
      end

    changeset |> put_change(:name, name)
  end

  defp validate_fields(changeset) do
    meta_id = get_field(changeset, :meta_id)
    year = get_field(changeset, :year_field)
    month = get_field(changeset, :month_field)
    day = get_field(changeset, :day_field)
    hour = get_field(changeset, :hour_field)
    minute = get_field(changeset, :minute_field)
    second = get_field(changeset, :second_field)
    field_namez = [year, month, day, hour, minute, second]

    meta = MetaActions.get(meta_id)
    fields = DataSetFieldActions.list_for_meta(meta)
    known_field_names = for f <- fields, do: f.name

    field_names = Enum.filter(field_namez, fn (name) -> name != nil end)
    is_subset = field_names |> Enum.all?(fn (name) -> Enum.member?(known_field_names, name) end)
    if is_subset do
      changeset
    else
      changeset |> add_error(:fields, "Field names must exist as registered fields of the data set")
    end
  end

  # Disallow update after the related Meta is in ready state
  defp check_meta_state(changeset) do
    meta =
      get_field(changeset, :meta_id)
      |> MetaActions.get()

    if meta.state == "ready" do
      changeset
      |> add_error(:name, "Cannot alter any fields after the parent data set has been approved. If you need to update this field, please contact the administrators.")
    else
      changeset
    end
  end
end
