defmodule Plenario.Actions.DataSetFieldActions do
  @moduledoc """
  This module provides a high level API for interacting with the
  DataSetField schema -- creating, updating, getting, ...
  """

  alias Plenario.Repo
  alias Plenario.Actions.MetaActions
  alias Plenario.Schemas.{Meta, DataSetField}
  alias Plenario.Changesets.DataSetFieldChangesets
  alias Plenario.Queries.DataSetFieldQueries

  import Ecto.Query

  @type ok_instance :: {:ok, DataSetField} | {:error, Ecto.Changeset.t()}

  @doc """
  This is a convenience function for generating empty changesets to more
  easily construct forms in Phoenix templates.
  """
  @spec new() :: Ecto.Changeset.t()
  def new(), do: DataSetFieldChangesets.new()

  @doc """
  Create a new instance of DataSetField in the database.

  If the related Meta instance's state field is not "new" though, this
  will error out -- you cannot add a new DataSetField to and active Meta.
  """
  @spec create(meta :: Meta | integer, name :: String.t(), type :: String.t()) :: ok_instance
  def create(%Meta{} = meta, name, type), do: create(meta.id, name, type)
  def create(meta, name, type) do
    params = %{meta_id: meta, name: name, type: type}
    DataSetFieldChangesets.create(params)
    |> Repo.insert()
  end

  @doc """
  This is a convenience function for generating prepopulated changesets
  to more easily construct change forms in Phoenix templates.
  """
  @spec edit(instance :: DataSetField) :: Ecto.Changeset.t()
  def edit(instance), do: DataSetFieldChangesets.update(instance, %{})

  @doc """
  Updates a given DataSetField's attributes.

  If the related Meta instance's state field is not "new" though, this
  will error out -- you cannot add a new DataSetField to and active Meta.
  """
  @spec update(instance :: DataSetField, opts :: Keyword.t()) :: ok_instance
  def update(instance, opts \\ []) do
    params = Enum.into(opts, %{})
    DataSetFieldChangesets.update(instance, params)
    |> Repo.update()
  end

  @doc """
  Gets a list of DataSetField from the database.

  This can be optionally filtered using the opts. See
  DataSetFieldQueries.handle_opts for more details.
  """
  @spec list(opts :: Keyword.t() | nil) :: list(DataSetField)
  def list(opts \\ []) do
    DataSetFieldQueries.list()
    |> DataSetFieldQueries.handle_opts(opts)
    |> Repo.all()
  end

  @doc """
  Gets a single DataSetField from the database.
  """
  @spec get(identifier :: integer) :: DataSetField | nil
  def get(identifier), do: Repo.get_by(DataSetField, id: identifier)

  @doc """
  Deletes a given DataSetField from the database.
  """
  @spec delete(field :: DataSetField) :: {:ok, DataSetField} | {:error, String.t()}
  def delete(field) do
    meta = MetaActions.get(field.meta_id)
    case meta.state do
      "new" -> Repo.delete(field)
      _ -> {:error, "Meta is locked."}
    end
  end

  def field_names(nil), do: []
  def field_names(ids) when is_list(ids) do
    Repo.all(from(d in DataSetField, where: d.id in ^ids, select: d.name))
  end
end
