defmodule Plenario.Actions.DataSetFieldActions do
  @moduledoc """
  This module provides a high level API for interacting with DataSetField
  structs -- creating, updating, listing, getting, ...
  """

  alias Plenario.Repo

  alias Plenario.Changesets.DataSetFieldChangesets

  alias Plenario.Schemas.{DataSetField, Meta}

  alias Plenario.Queries.DataSetFieldQueries

  @typedoc """
  Either a tuple of {:ok, field} or {:error, changeset}
  """
  @type ok_field :: {:ok, DataSetField} | {:error, Ecto.Changeset.t()}

  @doc """
  This is a convenience function for generating changesets to more easily create
  webforms in Phoenix templates.

  ## Example

    changeset = DataSetFieldActions.new()
    render(conn, "create.html", changeset: changeset)
    # And then in your template: <%= form_for @changeset, ... %>
  """
  @spec new() :: Ecto.Changeset.t()
  def new(), do: DataSetFieldChangesets.create(%{})

  @doc """
  Create a new DataSetField in the database. If the related Meta instance's
  state field is not "new" though, this will error out -- you cannot add
  a new field to an active meta.

  ## Example

    {:ok, field} = DataSetFieldActions.create(meta, "some_id", "integer")
  """
  @spec create(meta :: Meta, name :: String.t(), type :: String.t()) :: ok_field
  def create(meta, name, type) when not is_integer(meta), do: create(meta.id, name, type)

  @spec create(meta_id :: integer, name :: String.t(), type :: String.t()) :: ok_field
  def create(meta_id, name, type) do
    params = %{
      meta_id: meta_id,
      name: name,
      type: type
    }
    DataSetFieldChangesets.create(params)
    |> Repo.insert()
  end

  @doc """
  Updates a given DataSetField's name and/or type. If the related Meta
  instance's state field is not "new" though, this will error out -- you cannot
  update a field on an active meta.

  ## Example

    {:ok, field} = DataSetFieldActions.create(meta, "some_id", "integer")
    {:ok, _} = DataSetFieldActions.update(field, type: "text")
  """
  @spec update(field :: DataSetField, opts :: Keyword.t()) :: list(DataSetField)
  def update(field, opts) do
    params = Enum.into(opts, %{})
    DataSetFieldChangesets.update(field, params)
    |> Repo.update()
  end

  @doc """
  Gets a list of DataSetFields from the database. This can be optionally
  filtered using the opts. See DataSetFieldQueries.handle_opts for more details.

  ## Examples

    all_fields = DataSetFieldActions.list()
    my_metas_fields = DataSetFieldActions.list(for_meta: my_meta)
    specific_fields = DataSetFieldActions.list(by_ids: [123, 234, 345])
  """
  @spec list(opts :: Keyword.t() | nil) :: list(DataSetField)
  def list(opts \\ []) do
    DataSetFieldQueries.list()
    |> DataSetFieldQueries.handle_opts(opts)
    |> Repo.all()
  end

  @doc """
  Gets a single DataSetField by its id attribute.

  ## Example

    field = DataSetFieldActions.get(123)
  """
  @spec get(id :: integer) :: DataSetField | nil
  def get(id), do: Repo.get_by(DataSetField, id: id)
end
