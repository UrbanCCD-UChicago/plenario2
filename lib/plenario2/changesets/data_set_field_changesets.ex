defmodule Plenario2.Changesets.DataSetFieldChangesets do
  @moduledoc """
  This module provides functions for creating changesets for
  DataSetField structs.
  """

  import Ecto.Changeset

  alias Plenario2.Schemas.DataSetField

  @valid_types ~w{text integer float boolean timestamptz geometry(polygon,4326)}

  @doc """
  Creates a changeset for inserting a new DataSetField into the database
  """
  @spec create(struct :: %DataSetField{}, params :: %{}) :: Ecto.Changeset.t
  def create(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :type, :opts, :meta_id])
    |> validate_required([:name, :type, :opts, :meta_id])
    |> cast_assoc(:meta)
    |> check_name()
    |> validate_type()
  end

  # TODO: delete this? i don't know where we're using it or why we would...
  def make_primary_key(field) do
    field
    |> cast(%{}, [])
    |> put_change(:opts, "not null primary key")
  end

  # Converts name values to snake case
  # For example, if a user passes a field named "Event ID", this would return "event_id"
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

  # Validates the given type of the field is one we support, as defined in @valid_types
  defp validate_type(changeset) do
    type = get_field(changeset, :type)
    if Enum.member?(@valid_types, type) do
      changeset
    else
      changeset |> add_error(:type, "Invalid type selection")
    end
  end
end
