defmodule Plenario2.Core.Changesets.DataSetConstraintChangesets do
  import Ecto.Changeset
  alias Plenario2.Core.Actions.{MetaActions, DataSetFieldActions}
  alias Plenario2.Core.Schemas.Meta

  def create(struct, params) do
    struct
    |> cast(params, [:field_names, :meta_id])
    |> validate_required([:field_names, :meta_id])
    |> _validate_field_names()
    |> cast_assoc(:meta)
    |> _set_name()
  end

  ##
  # operations

  defp _set_name(changeset) do
    table_name =
      get_field(changeset, :meta_id)
      |> MetaActions.get_from_pk()
      |> Meta.get_dataset_table_name()

    field_names = get_field(changeset, :field_names) |> Enum.join("_")
    pieces = ["unique_constraint"] ++ [table_name] ++ [field_names]
    constraint_name = Enum.join(pieces, "_")

    changeset |> put_change(:constraint_name, constraint_name)
  end

  ##
  # validation

  defp _validate_field_names(changeset) do
    meta_id = get_field(changeset, :meta_id)
    field_names = get_field(changeset, :field_names)

    meta = MetaActions.get_from_pk(meta_id)
    fields = DataSetFieldActions.list_for_meta(meta)
    known_field_names = for f <- fields, do: f.name

    is_subset = field_names |> Enum.all?(fn (name) -> Enum.member?(known_field_names, name) end)
    if is_subset do
      changeset
    else
      changeset |> add_error(:field_names, "Field names must exist as registered fields of the dataset")
    end
  end
end
