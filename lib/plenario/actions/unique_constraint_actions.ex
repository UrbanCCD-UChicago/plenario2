defmodule Plenario.Actions.UniqueConstraintActions do
  @moduledoc """
  This module provides a high level API for interacting with UniqueConstraint
  structs -- creating, updating, listing, getting, ...
  """

  import Ecto.Query

  alias Plenario.Repo

  alias Plenario.Changesets.UniqueConstraintChangesets

  alias Plenario.Schemas.{DataSetField, UniqueConstraint}

  alias Plenario.Actions.DataSetFieldActions

  @typedoc """
  Either a tuple of {:ok, constraint} or {:error, changeset}
  """
  @type ok_constraint :: {:ok, UniqueConstraint} | {:error, Ecto.Changeset.t()}

  @doc """
  This is a convenience function for generating changesets to more easily create
  webforms in Phoenix templates.

  ## Example

    changeset = UniqueConstraintActions.new()
    render(conn, "create.html", changeset: changeset)
    # And then in your template: <%= form_for @changeset, ... %>
  """
  @spec new() :: Ecto.Changeset.t()
  def new(), do: UniqueConstraintChangesets.create(%{})

  @doc """
  Creates a new UniqueConstraint in the database. If the related Meta instance's
  state field is not "new" though, this will error out -- you cannot add a
  new constraint to an active meta.

  ## Example

    {:ok, constr} =
      UniqueConstraintActions.create(meta.id, [some_id_field.id])
  """
  @spec create(meta :: Meta | integer, field_ids :: list(DataSetField | integer)) :: ok_constraint
  def create(meta, field_ids) when not is_integer(meta), do: create(meta.id, field_ids)
  def create(meta_id, field_ids) do
    field_ids = extract_field_ids(field_ids)
    params = %{meta_id: meta_id, field_ids: field_ids}
    UniqueConstraintChangesets.create(params)
    |> Repo.insert()
  end

  @doc """
  Updates a given UniqueConstraint's referenced DataSetFields. If the related
  Meta instance's state field is not "new" though, this will error out --
  you cannot update a field on an active meta.

  ## Example

    {:ok, constr} =
      UniqueConstraintActions.create(meta.id, [some_id_field.id])
    {:ok, _} =
      UniqueConstraintActions.update([some_id_field.id, some_other_field.id])
  """
  @spec update(constraint :: UniqueConstraint, field_ids :: list(DataSetField | integer)) :: ok_constraint
  def update(constraint, field_ids \\ []) do
    field_ids = extract_field_ids(field_ids)
    params = %{field_ids: field_ids}
    UniqueConstraintChangesets.update(constraint, params)
    |> Repo.update()
  end

  @doc """
  Gets a list of UniqueConstraints, optionally filtered by their relationship
  to Meta given the `meta` param.
  """
  @spec list(meta :: Meta | integer | nil) :: list(UniqueConstraint)
  def list(), do: list(nil)
  def list(meta) when not is_integer(meta) and not is_nil(meta), do: list(meta.id)
  def list(meta) when is_integer(meta) or is_nil(meta) do
    query =
      case is_nil(meta) do
        true -> from(u in UniqueConstraint)
        false -> from(u in UniqueConstraint, where: u.meta_id == ^meta)
      end

    Repo.all(query)
  end

  @doc """
  Gets a single UniqueConstraint by its id attribute.

  ## Example

    constraint = UniqueConstraintActions.get(123)
  """
  @spec get(id :: integer) :: UniqueConstraint | nil
  def get(id), do: Repo.get_by(UniqueConstraint, id: id)

  @doc """
  Gets a list field names for the fields this constraint is built with.
  """
  def get_field_names(constraint) do
    fields = DataSetFieldActions.list(by_ids: constraint.field_ids)
    names = for f <- fields do f.name end

    names
  end

  defp extract_field_ids(field_list) do
    field_ids =
      for field <- field_list do
        if not is_integer(field) do
          field.id
        else
          field
        end
      end

    field_ids
  end
end
