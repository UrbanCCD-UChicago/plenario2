defmodule Plenario.Changesets.Utils do
  import Ecto.Changeset

  alias Plenario.Actions.MetaActions

  def validate_meta_state(%Ecto.Changeset{valid?: true} = changeset) do
    meta =
      get_field(changeset, :meta_id)
      |> MetaActions.get()

    case meta.state do
      "new" -> changeset
      _ -> add_error(changeset, :base, "Data set is locked")
    end
  end
  def validate_meta_state(changeset), do: changeset
end
