defmodule Plenario.Actions.UniqueConstraintActions do
  @moduledoc """
  This module provides a high level API for interacting with the
  UniqueConstraint schema -- creating, updating, getting, ...
  """

  alias Plenario.Repo

  alias Plenario.Schemas.{Meta, UniqueConstraint, DataSetField}

  alias Plenario.Changesets.UniqueConstraintChangesets

  alias Plenario.Queries.UniqueConstraintQueries

  alias Plenario.Actions.DataSetFieldActions

  @type ok_instance :: {:ok, UniqueConstraint} | {:error, Ecto.Changeset.t()}

  @doc """
  This is a convenience function for generating empty changesets to more
  easily construct forms in Phoenix templates.
  """
  @spec new() :: Ecto.Changeset.t()
  def new(), do: UniqueConstraintChangesets.new()

  @doc """
  Create a new instance of UniqueConstraint in the database.

  If the related Meta instance's state field is not "new" though, this
  will wrror out -- you cannot add a new UniqueConstraint to and active Meta.
  """
  @spec create(meta :: Meta | integer, field_ids :: list(DataSetField | integer)) :: ok_instance
  def create(meta, field_ids) when not is_integer(meta),
    do: create(meta.id, field_ids)
  def create(meta, field_ids) when is_integer(meta) do
    params = %{
      meta_id: meta,
      field_ids: extract_field_ids(field_ids)
    }
    UniqueConstraintChangesets.create(params)
    |> Repo.insert()
  end

  @doc """
  This is a convenience function for generating prepopulated changesets
  to more easily construct change forms in Phoenix templates.
  """
  @spec edit(instance :: UniqueConstraint) :: Ecto.Changeset.t()
  def edit(instance), do: UniqueConstraintChangesets.update(instance, %{})

  @doc """
  Updates a given UniqueConstraint's attributes.

  If the related Meta instance's state field is not "new" though, this
  will wrror out -- you cannot add a new UniqueConstraint to and active Meta.
  """
  @spec update(instance :: UniqueConstraint, opts :: Keyword.t()) :: ok_instance
  def update(instance, opts \\ []) do
    params = Enum.into(opts, %{})
    UniqueConstraintChangesets.update(instance, params)
    |> Repo.update()
  end

  @doc """
  Gets a list of UniqueConstraint from the database.

  This can be optionally filtered using the opts. See
  UniqueConstraintQueries.handle_opts for more details.
  """
  @spec list(opts :: Keyword.t()) :: list(UniqueConstraint)
  def list(opts \\ []) do
    UniqueConstraintQueries.list()
    |> UniqueConstraintQueries.handle_opts(opts)
    |> Repo.all()
  end

  @doc """
  Gets a single UniqueConstraint from the database.

  This can be optionally filtered using the opts. See
  UniqueConstraintQueries.handle_opts for more details.
  """
  @spec get(identifier :: integer) :: UniqueConstraint | nil
  def get(identifier), do: Repo.get_by(UniqueConstraint, id: identifier)

  @doc """
  Gets a list field names for the fields this constraint is built with.
  """
  @spec get_field_names(constraint :: UniqueConstraint) :: list(String.t())
  def get_field_names(constraint) do
    fields = DataSetFieldActions.list(by_ids: constraint.field_ids)
    names = for f <- fields do f.name end

    names
  end

  defp extract_field_ids(field_list) do
    field_ids =
      for field <- field_list do
        case is_integer(field) do
          true -> field
          false -> field.id
        end
      end

    field_ids
  end
end
