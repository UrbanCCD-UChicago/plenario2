defmodule Plenario2.Changesets.DataSetConstraintChangesets do
  @moduledoc """
  This module provides functions for creating changesets for
  DataSetConstraint structs.
  """

  import Ecto.Changeset

  alias Plenario2.Actions.{MetaActions, DataSetFieldActions}
  alias Plenario2.Schemas.DataSetConstraint

  @doc """
  Creates a changeset for creating new data set constraints in the database.

  Params include:

    - field_names
    - meta_id
  """
  @spec create(struct :: %DataSetConstraint{}, params :: %{}) :: Ecto.Changeset.t
  def create(struct, params) do
    struct
    |> cast(params, [:field_names, :meta_id])
    |> validate_required([:field_names, :meta_id])
    |> validate_field_names()
    |> cast_assoc(:meta)
    |> set_name()
  end

  # TODO: i hate this -- maybe this should be something like def new(), do: %DataSetConstraint{} |> cast(%{}, [:field_names, :meta_id])
  @doc """
  Creates a blank changeset for building forms in web templates
  """
  @spec blank(struct :: %DataSetConstraint{}) :: Ecto.Changeset.t
  def blank(struct) do
    struct
    |> cast(%{}, [:field_names, :meta_id])
  end

  # Sets the name of the constraint by prefixing `unique_constraint` and then underscore joining the field names.
  # For example, if we have 2 fields to create a constraint as ("name", "location"), the result of this
  # function would be "unique_constraint_name_location"
  defp set_name(changeset) do
    table_name =
      get_field(changeset, :meta_id)
      |> MetaActions.get_from_id()
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

    meta = MetaActions.get_from_id(meta_id)
    fields = DataSetFieldActions.list_for_meta(meta)
    known_field_names = for f <- fields, do: f.name

    is_subset = field_names |> Enum.all?(fn (name) -> Enum.member?(known_field_names, name) end)
    if is_subset do
      changeset
    else
      changeset |> add_error(:field_names, "Field names must exist as registered fields of the data set")
    end
  end
end
