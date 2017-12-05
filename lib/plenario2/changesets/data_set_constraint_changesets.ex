defmodule Plenario2.Changesets.DataSetConstraintChangesets do
  import Ecto.Changeset
  alias Plenario2.Actions.{MetaActions, DataSetFieldActions}
  alias Plenario2.Schemas.Meta

  def create(struct, params) do
    struct
    |> cast(params, [:field_names, :meta_id])
    |> validate_required([:field_names, :meta_id])
    |> validate_field_names()
    |> cast_assoc(:meta)
    |> set_name()
  end

  ##
  # operations

  defp set_name(changeset) do
    table_name =
      get_field(changeset, :meta_id)
      |> MetaActions.get_from_id()
      |> Meta.get_data_set_table_name()

    field_names = get_field(changeset, :field_names) |> Enum.join("_")
    pieces = ["unique_constraint"] ++ [table_name] ++ [field_names]
    constraint_name = Enum.join(pieces, "_")

    changeset |> put_change(:constraint_name, constraint_name)
  end

  ##
  # validation

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
