defmodule Plenario.Actions.VirtualPointFieldActions do
  @moduledoc """
  This module provides a high level API for interacting with the
  VirtualPointField schema -- creating, updating, getting, ...
  """

  alias Plenario.Repo

  alias Plenario.Schemas.{Meta, VirtualPointField}

  alias Plenario.Changesets.VirtualPointFieldChangesets

  alias Plenario.Queries.VirtualPointFieldQueries

  @type ok_instance :: {:ok, VirtualPointField} | {:error, Ecto.Changeset.t()}

  @doc """
  This is a convenience function for generating empty changesets to more
  easily construct forms in Phoenix templates.
  """
  @spec new() :: Ecto.Changeset.t()
  def new(), do: VirtualPointFieldChangesets.new()

  @doc """
  Create a new instance of VirtualPointField in the database.

  If the related Meta instance's state field is not "new" though, this
  will wrror out -- you cannot add a new VirtualPointField to and active Meta.
  """
  @spec create(meta :: Meta | integer, lat_field_id :: integer, lon_fiel_id :: integer) :: ok_instance
  def create(%Meta{} = meta, lat_field_id, lon_field_id), do: create(meta.id, lat_field_id, lon_field_id)
  def create(meta, lat_field_id, lon_field_id) do
    params = %{
      meta_id: meta,
      lat_field_id: lat_field_id,
      lon_field_id: lon_field_id
    }
    create(params)
  end

  @spec create(meta :: Meta | integer, loc_field_id :: integer) :: ok_instance
  def create(%Meta{} = meta, loc_field_id), do: create(meta.id, loc_field_id)
  def create(meta, loc_field_id) do
    params = %{
      meta_id: meta,
      loc_field_id: loc_field_id
    }
    create(params)
  end

  defp create(params), do: VirtualPointFieldChangesets.create(params) |> Repo.insert()

  @doc """
  This is a convenience function for generating prepopulated changesets
  to more easily construct change forms in Phoenix templates.
  """
  @spec edit(instance :: VirtualPointField) :: Ecto.Changeset.t()
  def edit(instance), do: VirtualPointFieldChangesets.update(instance, %{})

  @doc """
  Updates a given VirtualPointField's attributes.

  If the related Meta instance's state field is not "new" though, this
  will wrror out -- you cannot add a new VirtualPointField to and active Meta.
  """
  @spec update(instance :: VirtualPointField, opts :: Keyword.t()) :: ok_instance
  def update(instance, opts \\ []) do
    params = Enum.into(opts, %{})
    VirtualPointFieldChangesets.update(instance, params)
    |> Repo.update()
  end

  @doc """
  Gets a list of VirtualPointField from the database.

  This can be optionally filtered using the opts. See
  VirtualPointFieldQueries.handle_opts for more details.
  """
  @spec list(opts :: Keyword.t() | nil) :: list(VirtualPointField)
  def list(opts \\ []) do
    VirtualPointFieldQueries.list()
    |> VirtualPointFieldQueries.handle_opts(opts)
    |> Repo.all()
  end

  @doc """
  Gets a single VirtualPointField from the database.

  This can be optionally filtered using the opts. See
  VirtualPointFieldQueries.handle_opts for more details.
  """
  @spec get(identifier :: integer) :: VirtualPointField | nil
  def get(identifier), do: Repo.get_by(VirtualPointField, id: identifier)

  @doc """
  Deletes a given VirtualPointField from the database.
  """
  @spec delete(field :: VirtualPointField) :: {:ok, VirtualPointField}
  def delete(field), do: Repo.delete(field)
end
