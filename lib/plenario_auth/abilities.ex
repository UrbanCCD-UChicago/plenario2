defmodule PlenarioAuth.Abilities do
  @moduledoc """
  Defines auhtorization capabilities for users in relation to resources. For example, we only
  want the user who owns a meta to be able to edit it.
  """

  alias Plenario.Schemas.{
    User,
    Meta,
    DataSetField,
    VirtualDateField,
    VirtualPointField,
    UniqueConstraint
  }

  alias Plenario.Actions.MetaActions

  defimpl Canada.Can, for: User do

    @doc """
    For all create, edit, delete actions of a Meta, ensure the user is the owner
    otherwaise disallow.
    """
    def can?(nil, _, _ = %Meta{}), do: false
    def can?(%User{id: user_id}, _, meta = %Meta{}), do: meta.user_id == user_id

    @doc """
    For all create, edit, delete actions of a DataSetField, ensure the user
    is the owner of the related Meta otherwaise disallow.
    """
    def can?(nil, _, _ = %DataSetField{}), do: false
    def can?(%User{id: user_id}, _, field = %DataSetField{}) do
      meta = MetaActions.get(field.meta_id)
      meta.user_id == user_id
    end

    @doc """
    For all create, edit, delete actions of a VirtualDateField, ensure the user
    is the owner of the related Meta otherwaise disallow.
    """
    def can?(nil, _, _ = %VirtualDateField{}), do: false
    def can?(%User{id: user_id}, _, field = %VirtualDateField{}) do
      meta = MetaActions.get(field.meta_id)
      meta.user_id == user_id
    end

    @doc """
    For all create, edit, delete actions of a VirtualPointField, ensure the user
    is the owner of the related Meta otherwaise disallow.
    """
    def can?(nil, _, _ = %VirtualPointField{}), do: false
    def can?(%User{id: user_id}, _, field = %VirtualPointField{}) do
      meta = MetaActions.get(field.meta_id)
      meta.user_id == user_id
    end

    @doc """
    For all create, edit, delete actions of a UniqueConstraint, ensure the user
    is the owner of the related Meta otherwaise disallow.
    """
    def can?(nil, _, _ = %UniqueConstraint{}), do: false
    def can?(%User{id: user_id}, _, constraint = %UniqueConstraint{}) do
      meta = MetaActions.get(constraint.meta_id)
      meta.user_id == user_id
    end
  end
end
