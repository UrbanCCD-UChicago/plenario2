defmodule Plenario2.Changesets.DataSetFieldChangesets do
  import Ecto.Changeset

  @valid_types ~w(text integer float boolean timestamptz)

  def create(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :type, :opts, :meta_id])
    |> validate_required([:name, :type, :opts, :meta_id])
    |> cast_assoc(:meta)
    |> check_name()
    |> validate_type()
  end

  def make_primary_key(field) do
    field
    |> cast(%{}, [])
    |> put_change(:opts, "not null primary key")
  end

  ##
  # operations

  defp check_name(changeset) do
    name = case get_field(changeset, :name) do
      nil ->
        nil

      name ->
        String.split(name, ~r/\s/, trim: true)
        |> Enum.map(&String.downcase(&1))
        |> Enum.join("_")
    end

    changeset |> put_change(:name, name)
  end

  ##
  # validation

  defp validate_type(changeset) do
    type = get_field(changeset, :type)
    if Enum.member?(@valid_types, type) do
      changeset
    else
      changeset |> add_error(:type, "Invalid type selection")
    end
  end
end
