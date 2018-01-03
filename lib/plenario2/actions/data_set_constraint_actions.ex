defmodule Plenario2.Actions.DataSetConstraintActions do
  @moduledoc """
  This module provides a common API for the business logic
  underlying the various public interfaces for DataSetConstraint.
  """

  import Ecto.Query

  alias Plenario2.Changesets.DataSetConstraintChangesets
  alias Plenario2.Schemas.{DataSetConstraint, Meta}
  alias Plenario2.Repo

  @doc """
  Creates a new instance of a DataSetConstraint.
  """
  @spec create(meta_id :: integer, field_names :: [String.t]) :: {:ok, %DataSetConstraint{} | :error, Ecto.Changeset.t}
  def create(meta_id, field_names) do
    params = %{
      meta_id: meta_id,
      field_names: field_names
    }

    DataSetConstraintChangesets.create(%DataSetConstraint{}, params)
    |> Repo.insert()
  end

  @doc """
  Lists all the constraints related to a given Meta.
  """
  @spec list_for_meta(meta :: %Meta{}) :: [%DataSetConstraint{}]
  def list_for_meta(meta), do: Repo.all(from c in DataSetConstraint, where: c.meta_id == ^meta.id)

  @doc """
  Deletes a given constraint.
  """
  @spec delete(constraint :: %DataSetConstraint{}) :: {:ok, %DataSetConstraint{} | :error, Ecto.Changeset.t}
  def delete(constraint), do: Repo.delete(constraint)
end
