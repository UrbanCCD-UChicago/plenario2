defmodule Plenario.Actions.VirtualDateFieldActions do
  @moduledoc """
  This module provides a high level API for interacting with the
  VirtualDateField schema -- creating, updating, getting, ...
  """

  alias Plenario.Repo

  alias Plenario.Actions.MetaActions

  alias Plenario.Schemas.{Meta, VirtualDateField}

  alias Plenario.Changesets.VirtualDateFieldChangesets

  alias Plenario.Queries.VirtualDateFieldQueries

  @type ok_instance :: {:ok, VirtualDateField} | {:error, Ecto.Changeset.t()}

  @doc """
  This is a convenience function for generating empty changesets to more
  easily construct forms in Phoenix templates.
  """
  @spec new() :: Ecto.Changeset.t()
  def new(), do: VirtualDateFieldChangesets.new()

  @doc """
  Create a new instance of VirtualDateField in the database.

  The `opts` param is a keyword list of the other possible related data set
  field's ID attributes.

  If the related Meta instance's state field is not "new" though, this
  will wrror out -- you cannot add a new VirtualDateField to and active Meta.
  """
  @spec create(meta :: Meta | integer, year_field_id :: integer, opts :: Keyword.t()) :: ok_instance
  def create(meta, year_field_id), do: create(meta, year_field_id, [])
  def create(%Meta{} = meta, year_field_id, opts), do: create(meta.id, year_field_id, opts)
  def create(meta, year_field_id, opts) do
    params =
      [meta_id: meta, year_field_id: year_field_id]
      |> Keyword.merge(opts)
      |> Enum.into(%{})
    VirtualDateFieldChangesets.create(params)
    |> Repo.insert()
  end

  @doc """
  This is a convenience function for generating prepopulated changesets
  to more easily construct change forms in Phoenix templates.
  """
  @spec edit(instance :: VirtualDateField) :: Ecto.Changeset.t()
  def edit(instance), do: VirtualDateFieldChangesets.update(instance, %{})

  @doc """
  Updates a given VirtualDateField's attributes.

  If the related Meta instance's state field is not "new" though, this
  will wrror out -- you cannot add a new VirtualDateField to and active Meta.
  """
  @spec update(instance :: VirtualDateField, opts :: Keyword.t()) :: ok_instance
  def update(instance, opts \\ []) do
    params = Enum.into(opts, %{})
    VirtualDateFieldChangesets.update(instance, params)
    |> Repo.update()
  end

  @doc """
  Gets a list of VirtualDateField from the database.

  This can be optionally filtered using the opts. See
  VirtualDateFieldQueries.handle_opts for more details.
  """
  @spec list(opts :: Keyword.t() | nil) :: list(VirtualDateField)
  def list(opts \\ []) do
    VirtualDateFieldQueries.list()
    |> VirtualDateFieldQueries.handle_opts(opts)
    |> Repo.all()
  end

  @doc """
  Gets a single VirtualDateField from the database.

  This can be optionally filtered using the opts. See
  VirtualDateFieldQueries.handle_opts for more details.
  """
  @spec get(identifier :: integer) :: VirtualDateField | nil
  def get(identifier), do: Repo.get_by(VirtualDateField, id: identifier)

  @doc """
  Deletes a given VirtualDateField from the database.
  """
  @spec delete(field :: VirtualDateField) :: {:ok, VirtualDateField} | {:error, String.t()}
  def delete(field) do
    meta = MetaActions.get(field.meta_id)
    case meta.state do
      "new" -> Repo.delete(field)
      _ -> {:error, "Meta is locked."}
    end
  end
end
