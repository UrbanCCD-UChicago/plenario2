defmodule Plenario2.Core.Changesets.EtlJobChangeset do
  import Ecto.Changeset

  def create(struct, params) do
    struct
    |> cast(params, [:meta_id])
    |> validate_required([:meta_id])
    |> cast_assoc(:meta)
    |> put_change(:state, "new")
  end
end
