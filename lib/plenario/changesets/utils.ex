defmodule Plenario.Changesets.Utils do
  import Ecto.Changeset

  alias Plenario.Actions.MetaActions

  @name_length 16

  def validate_meta_state(%Ecto.Changeset{valid?: true} = changeset) do
    meta = MetaActions.get(get_field(changeset, :meta_id))
    case meta.state do
      "new" -> changeset
      _ -> add_error(changeset, :base, "Data set is locked")
    end
  end
  def validate_meta_state(changeset), do: changeset

  def set_random_name(%Ecto.Changeset{valid?: true} = changeset, prefix) do
    rand =
      :crypto.strong_rand_bytes(@name_length)
      |> Base.url_encode64()
      |> binary_part(0, @name_length)

    name = "#{prefix}_#{rand}"
    put_change(changeset, :name, name)
  end
  def set_random_name(changeset, _), do: changeset
end
