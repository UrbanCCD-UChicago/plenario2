defmodule Plenario2.Actions.DataSetConstraintActions do
  @moduledoc """
  This module provides a common API for the business logic
  underlying the various public interfaces for DataSetConstraint.
  """

  import Ecto.Query

  import Plenario2.Guards, only: [is_id: 1]

  alias Plenario2.Changesets.DataSetConstraintChangesets
  alias Plenario2.Schemas.{DataSetConstraint, Meta}
  alias Plenario2.Repo

  require Logger

  @typedoc """
  Parameter is an ID attribute
  """
  @type id :: String.t() | integer

  @typedoc """
  Returns a tuple of :ok, DataSetConstraint or :error, Ecto.Changeset
  """
  @type ok_constr :: {:ok, DataSetConstraint} | {:error, Ecto.Changeset.T}

  @doc """
  Creates a new instance of a DataSetConstraint.
  """
  @spec create(meta :: Meta | id, field_names :: [String.t()]) :: ok_constr
  def create(meta, field_names) do
    meta_id =
      case is_id(meta) do
        true -> meta
        false -> meta.id
      end

    params = %{
      meta_id: meta_id,
      field_names: field_names
    }

    Logger.info("Creating DataSetConstraint: #{inspect(params)}")

    DataSetConstraintChangesets.create(params)
    |> Repo.insert()
  end

  @doc """
  Lists all the constraints related to a given Meta.
  """
  @spec list_for_meta(meta :: Meta | id) :: list(DataSetConstraint)
  def list_for_meta(meta) do
    meta_id =
      case is_id(meta) do
        true -> meta
        false -> meta.id
      end

    Repo.all(from(c in DataSetConstraint, where: c.meta_id == ^meta_id))
  end

  def get(id) do
    Repo.one(
      from(
        c in DataSetConstraint,
        where: c.id == ^id,
        preload: [meta: :data_set_constraints]
      )
    )
  end

  @doc """
  Updates a DataSetConstraint
  """
  @spec update(constraint :: DataSetConstraint, parmas :: map) :: DataSetConstraint
  def update(constraint, params) do
    Logger.info("Updating DataSetConstraint: #{inspect(constraint)}, #{inspect(params)}")

    DataSetConstraintChangesets.update(constraint, params)
    |> Repo.update()
  end

  @doc """
  Deletes a given constraint.
  """
  @spec delete(constraint :: %DataSetConstraint{}) ::
          {:ok, %DataSetConstraint{} | :error, Ecto.Changeset.t()}
  def delete(constraint) do
    Logger.info("Deleting DataSetConstraint: #{inspect(constraint)}")
    Repo.delete(constraint)
  end
end
