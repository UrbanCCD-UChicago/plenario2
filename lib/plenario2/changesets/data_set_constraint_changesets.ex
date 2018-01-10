defmodule Plenario2.Changesets.DataSetConstraintChangesets do
  @moduledoc """
  This module provides functions for creating changesets for
  DataSetConstraint structs.
  """

  import Ecto.Changeset

  alias Plenario2.Actions.{MetaActions, DataSetFieldActions}
  alias Plenario2.Schemas.DataSetConstraint

  @typedoc """
  Verbose map of params for create
  """
  @type create_params :: %{
    field_names: list(String.t),
    meta_id: integer
  }

  @new_create_param_keys [:field_names, :meta_id]

  @doc """
  Creates a blank changeset for webforms
  """
  @spec new() :: Ecto.Changeset.t
  def new() do
    %DataSetConstraint{}
    |> cast(%{}, @new_create_param_keys)
  end

  @doc """
  Creates a changeset for creating new data set constraints in the database
  """
  @spec create(params :: create_params) :: Ecto.Changeset.t
  def create(params) do
    %DataSetConstraint{}
    |> cast(params, @new_create_param_keys)
    |> validate_required(@new_create_param_keys)
    |> validate_field_names()
    |> cast_assoc(:meta)
    |> set_name()
  end

  @doc """
  Updates a given unique constraint
  """
  @spec update(constraint :: DataSetConstraint, params :: create_params) :: Ecto.Changeset.t
  def update(constraint, params \\ %{}) do
    constraint
    |> cast(params, @new_create_param_keys)
    |> validate_required(@new_create_param_keys)
    |> validate_field_names()
    |> cast_assoc(:meta)
    |> set_name()
    |> check_meta_state()
  end

  # Sets the name of the constraint by prefixing `unique_constraint` and then underscore joining the field names.
  # For example, if we have 2 fields to create a constraint as ("name", "location"), the result of this
  # function would be "unique_constraint_name_location"
  defp set_name(changeset) do
    table_name =
      get_field(changeset, :meta_id)
      |> MetaActions.get()
      |> MetaActions.get_data_set_table_name()

    field_names = get_field(changeset, :field_names) |> Enum.join("_")
    pieces = ["unique_constraint"] ++ [table_name] ++ [field_names]
    constraint_name = Enum.join(pieces, "_")

    changeset |> put_change(:constraint_name, constraint_name)
  end

  # Validates that the given field names are fields associated to the same meta
  defp validate_field_names(changeset) do
    meta_id = get_field(changeset, :meta_id)
    field_names = get_field(changeset, :field_names)

    meta = MetaActions.get(meta_id)
    fields = DataSetFieldActions.list_for_meta(meta)
    known_field_names = for f <- fields, do: f.name

    is_subset = field_names |> Enum.all?(fn (name) -> Enum.member?(known_field_names, name) end)
    if is_subset do
      changeset
    else
      changeset |> add_error(:field_names, "Field names must exist as registered fields of the data set")
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
