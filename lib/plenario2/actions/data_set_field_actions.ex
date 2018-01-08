defmodule Plenario2.Actions.DataSetFieldActions do
  @moduledoc """
  This module provides a common API for the business logic
  underlying the various public interfaces for DataSetField.
  """

  import Ecto.Query

  import Plenario2.Guards, only: [is_id: 1]

  alias Plenario2.Changesets.DataSetFieldChangesets
  alias Plenario2.Schemas.{DataSetField, Meta}
  alias Plenario2.Repo

  @typedoc """
  Parameter is an ID attribute
  """
  @type id :: String.t | integer

  @typedoc """
  Returns a tuple of :ok, DataSetField or :error, Ecto.Changeset
  """
  @type ok_field :: {:ok, DataSetField} | {:error, Ecto.Changeset.T}

  @doc """
  Crates a new instance of DataSetField
  """
  @spec create(meta :: Meta | id, name :: String.t, type :: String.t, opts :: String.t) :: ok_field
  def create(meta, name, type, opts \\ "default null") do
    meta_id =
      case is_id(meta) do
        true -> meta
        false -> meta.id
      end

    params = %{
      meta_id: meta_id,
      name: name,
      type: type,
      opts: opts
    }

    DataSetFieldChangesets.create(params)
    |> Repo.insert()
  end

  @doc """
  Gets a list of fields related to a given Meta
  """
  @spec list_for_meta(meta :: Meta | id) :: list(DataSetField)
  def list_for_meta(meta) do
    meta_id =
      case is_id(meta) do
        true -> meta
        false -> meta.id
      end

    Repo.all(
      from f in DataSetField,
      where: f.meta_id == ^meta_id
    )
  end

  @doc """
  Updates a DataSetField
  """
  @spec update(field :: DataSetField, params :: map) :: DataSetField
  def update(field, params) do
    DataSetFieldChangesets.update(field, params)
    |> Repo.update()
  end

  def make_primary_key(field) do
    DataSetFieldChangesets.make_primary_key(field)
    |> Repo.update()
  end

  @doc """
  Deletes a given data set field
  """
  @spec delete(field :: %DataSetField{}) :: {:ok, %DataSetField{} | :error, Ecto.Changeset.t}
  def delete(field), do: Repo.delete(field)
end
