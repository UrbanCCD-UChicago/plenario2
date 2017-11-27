defmodule Plenario2.Changesets.DataSetFieldChangesets do
  import Ecto.Changeset

  def create(struct, params) do
    struct
    |> cast(params, [:name, :type, :opts, :meta_id])
    |> validate_required([:name, :type, :opts, :meta_id])
    |> cast_assoc(:meta)
    |> _check_name()
  end

  def make_primary_key(field) do
    field
    |> cast(%{}, [])
    |> put_change(:opts, "not null primary key")
  end

  ##
  # operations

  defp _check_name(changeset) do
    name =
      get_field(changeset, :name)
      |> String.split(~r/\s/, trim: true)
      |> Enum.map(&String.downcase(&1))
      |> Enum.join("_")

    changeset |> put_change(:name, name)
  end
end
