defmodule Plenario2.Core.Changesets.DataSetConstraintChangeset do
  import Ecto.Changeset
  alias Plenario2.Core.Actions.MetaActions

  def create(struct, params) do
    struct
    |> cast(params, [:field_names, :meta_id])
    |> validate_required([:field_names, :meta_id])
    |> cast_assoc(:meta)
    |> _set_name()
  end

  ##
  # operations

  defp _set_name(changeset) do
    table_name =
      get_field(changeset, :meta_id)
      |> MetaActions.get_meta_from_pk!()
      |> MetaActions.get_table_name()

    field_names = get_field(changeset, :field_names)
    pieces = ["unique_constraint"] ++ [table_name] ++ [field_names]
    constraint_name = Enum.join(pieces, "_")

    changeset |> put_change(:constraint_name, constraint_name)
  end
end
