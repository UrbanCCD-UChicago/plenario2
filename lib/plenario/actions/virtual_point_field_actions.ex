defmodule Plenario.Actions.VirtualPointFieldActions do
  @moduledoc """
  This module provides a high level API for interacting with VirtualPointField
  structs -- creating, updating, listing, getting, ...
  """

  alias Plenario.Repo

  alias Plenario.Changesets.VirtualPointFieldChangesets

  alias Plenario.Schemas.VirtualPointField

  alias Plenario.Queries.VirtualPointFieldQueries

  @typedoc """
  Either a tuple of {:ok, field} or {:error, changeset}
  """
  @type ok_field :: {:ok, VirtualPointField} | {:error, Ecto.Changeset.t()}

  @doc """
  This is a convenience function for generating changesets to more easily create
  webforms in Phoenix templates.

  ## Example

    changeset = VirtualPointFieldActions.new()
    render(conn, "create.html", changeset: changeset)
    # And then in your template: <%= form_for @changeset, ... %>
  """
  @spec new() :: Ecto.Changeset.t()
  def new(), do: VirtualPointFieldChangesets.create(%{})

  @doc """
  Creates a new VirtualPointField in the database. If the related Meta instance's
  state field is not "new" though, this will error out -- you cannot add a
  new field to an active meta.

  ## Examples

    {:ok, field} =
      VirtualPointFieldActions.create(
        meta.id, some_lat_field.id, some_lon_field.id
      )

    {:ok, field} =
      VirtualPointFieldActions.create(meta.id, some_loc_field.id)
  """
  @spec create(meta_id :: integer, lat_field_id :: integer, lon_field_id :: integer) :: ok_field
  def create(meta_id, lat_field_id, lon_field_id) do
    params = %{
      meta_id: meta_id,
      lat_field_id: lat_field_id,
      lon_field_id: lon_field_id
    }
    VirtualPointFieldChangesets.create(params)
    |> Repo.insert()
  end

  @spec create(meta_id :: integer, loc_field_id :: integer) :: ok_field
  def create(meta_id, loc_field_id) do
    params = %{
      meta_id: meta_id,
      loc_field_id: loc_field_id
    }
    VirtualPointFieldChangesets.create(params)
    |> Repo.insert()
  end

  @doc """
  Updates a given VirtualPointField's referenced DataSetFields. If the related
  Meta instance's state field is not "new" though, this will error out --
  you cannot update a field on an active meta.

  The :opts param is a keyword list of the *_field_id attributes and are
  expected to be the ID attributes of the fields.

  ## Example

    {:ok, field} =
      VirtualPointFieldActions.create(
        meta.id, some_lat_field.id, some_lon_field.id
      )
    {:ok, _} =
      VirtualPointFieldActions.update(field, lat_field_id: some_lat_field.id)
  """
  @spec update(field :: VirtualDateField, opts :: Keyword.t()) :: ok_field
  def update(field, opts \\ []) do
    params = Enum.into(opts, %{})
    VirtualPointFieldChangesets.update(field, params)
    |> Repo.update()
  end

  @doc """
  Gets a list of VirtualPointFields from the database. This can be optionally
  filtered using the opts. See VirtualDateFieldQueries.handle_opts for
  more details.

  ## Examples

    all_fields = VirtualPointFieldActions.list()
    my_metas_fields = VirtualPointFieldActions.list(for_meta: my_meta)
  """
  @spec list(opts :: Keyword.t() | nil) :: list(VirtualPointField)
  def list(opts \\ []) do
    VirtualPointFieldQueries.list()
    |> VirtualPointFieldQueries.handle_opts(opts)
    |> Repo.all()
  end

  @doc """
  Gets a single VirtualPointField by its id attribute.

  ## Example

    field = VirtualPointFieldActions.get(123)
  """
  @spec get(id :: integer) :: VirtualPointField | nil
  def get(id), do: Repo.get_by(VirtualPointField, id: id)
end
