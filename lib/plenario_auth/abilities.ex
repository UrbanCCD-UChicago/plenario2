defmodule PlenarioAuth.Abilities do
  @moduledoc """
  Defines authorization abilities for users in relation to resources. For
  example, we only want the user who owns a meta to be able to edit it.
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

  defimpl Canada.Can, for: Atom do

    @doc """
    Anonymous users can only access the :index and :show actions of
    Metas and Users.
    """
    def can?(nil, action, %Meta{}) when action in [:index, :show], do: true
    def can?(nil, action, %User{}) when action in [:index, :show], do: true
    def can?(nil, _, _), do: false
  end

  defimpl Canada.Can, for: User do

    @doc """
    Admin users can perform any action, regardless of who owns the resource.
    """
    def can?(%User{is_admin: true}, _, _), do: true

    @doc """
    Authenticated users can only access the Meta index and show, unless they
    are the owner of the Meta.
    """
    def can?(%User{id: user_id}, _, %Meta{user_id: user_id}), do: true
    def can?(%User{}, action, Meta) when action in [:new, :create], do: true
    def can?(%User{}, action, %Meta{}) when action in [:show], do: true
    def can?(%User{}, _, %Meta{}), do: false

    @doc """
    Authenticated users who own the DataSetField's parent Meta are the only
    users able to access it.
    """
    def can?(%User{id: user_id}, _, %DataSetField{meta_id: meta_id}) do
      meta = MetaActions.get(meta_id)
      meta.user_id == user_id
    end

    @doc """
    Authenticated users who own the VirtualDateField's parent Meta are the only
    users able to access it.
    """
    def can?(%User{id: user_id}, _, %VirtualDateField{meta_id: meta_id}) do
      meta = MetaActions.get(meta_id)
      meta.user_id == user_id
    end

    @doc """
    Authenticated users who own the VirtualPointField's parent Meta are the only
    users able to access it.
    """
    def can?(%User{id: user_id}, _, %VirtualPointField{meta_id: meta_id}) do
      meta = MetaActions.get(meta_id)
      meta.user_id == user_id
    end

    @doc """
    Authenticated users who own the UniqueConstraint's parent Meta are the only
    users able to access it.
    """
    def can?(%User{id: user_id}, _, %UniqueConstraint{meta_id: meta_id}) do
      meta = MetaActions.get(meta_id)
      meta.user_id == user_id
    end
  end
end
