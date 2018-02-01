defmodule Plenario.Actions.VirtualDateFieldActions do
  @moduledoc """
  This module provides a high level API for interacting with VirtualDateField
  structs -- creating, updating, listing, getting, ...
  """

  alias Plenario.Repo

  alias Plenario.Changesets.VirtualDateFieldChangesets

  alias Plenario.Schemas.VirtualDateField

  alias Plenario.Queries.VirtualDateFieldQueries

  @typedoc """
  Either a tuple of {:ok, field} or {:error, changeset}
  """
  @type ok_field :: {:ok, VirtualDateField} | {:error, Ecto.Changeset.t()}

  @doc """
  This is a convenience function for generating changesets to more easily create
  webforms in Phoenix templates.

  ## Example

    changeset = VirtualDateFieldActions.new()
    render(conn, "create.html", changeset: changeset)
    # And then in your template: <%= form_for @changeset, ... %>
  """
  @spec new() :: Ecto.Changeset.t()
  def new(), do: VirtualDateFieldChangesets.create(%{})

  @doc """
  Creates a new VirtualDateField in the database. If the related Meta instance's
  state field is not "new" though, this will error out -- you cannot add a
  new field to an active meta.

  The optional params are the month, day, hour, minute and second field ids.
  They are expected to be the ID attributes of those related fields.

  ## Example

    {:ok, field} =
      VirtualDateFieldActions.create(
        meta.id, some_yr_field.id, month_field_id: some_mo_field.id
      )
  """
  @spec create(meta_id :: integer, year_field_id :: integer) :: ok_field
  def create(meta_id, year_field_id), do: create(meta_id, year_field_id, [])

  @spec create(meta_id :: integer, year_field_id :: integer, opts :: Keyword.t()) :: ok_field
  def create(meta_id, year_field_id, opts) do
    params =
      [meta_id: meta_id, year_field_id: year_field_id]
      |> Keyword.merge(opts)
      |> Enum.into(%{})

    VirtualDateFieldChangesets.create(params)
    |> Repo.insert()
  end

  @doc """
  Updates a given VirtualDateField's referenced DataSetFields. If the related
  Meta instance's state field is not "new" though, this will error out --
  you cannot update a field on an active meta.

  The :opts param is a keyword list of the *_field_id attributes and are
  expected to be the ID attributes of the fields.

  ## Example

    {:ok, field} =
      VirtualDateFieldActions.create(
        meta, some_yr_field.id, month_field_id: some_mo_field.id
      )
    {:ok, _} =
      VirtualDateFieldActions.update(field, day_field_id: some_day_field.id)
  """
  @spec update(field :: VirtualDateField, opts :: Keyword.t()) :: ok_field
  def update(field, opts) do
    params = Enum.into(opts, %{})
    VirtualDateFieldChangesets.update(field, params)
    |> Repo.update()
  end

  @doc """
  Gets a list of VirtualDateFields from the database. This can be optionally
  filtered using the opts. See VirtualDateFieldQueries.handle_opts for
  more details.

  ## Examples

    all_fields = VirtualDateFieldActions.list()
    my_metas_fields = VirtualDateFieldActions.list(for_meta: my_meta)
  """
  @spec list(opts :: Keyword.t() | nil) :: list(VirtualDateField)
  def list(opts \\ []) do
    VirtualDateFieldQueries.list()
    |> VirtualDateFieldQueries.handle_opts(opts)
    |> Repo.all()
  end

  @doc """
  Gets a single VirtualDateField by its id attribute.

  ## Example

    field = VirtualDateFieldActions.get(123)
  """
  @spec get(id :: integer) :: VirtualDateField | nil
  def get(id), do: Repo.get_by(VirtualDateField, id: id)
end
