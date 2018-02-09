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

  defimpl Canada.Can, for: User do

    @doc """
    Admin users can perform any action, regardless of who owns the resource.
    """
    def can?(%User{is_admin: true}, _, _), do: true

    @doc """
    Anonymous users can only access the Meta index and show.
    """
    def can?(nil, action, %Meta{}) when action in [:index, :show], do: true
    def can?(nil, _, %Meta{}), do: false

    @doc """
    Authenticated users can only access the Meta index and show, unless they
    are the owner of the Meta.
    """
    def can?(%User{id: user_id}, _, %Meta{user_id: user_id}), do: true
    def can?(%User{id: user_id}, action, %Meta{}) when action in [:index, :show], do: true
    def can?(%User{id: user_id}, _, %Meta{}), do: false

    @doc """
    Anonymous users have no access to DataSetField.
    """
    def can?(nil, _, %DataSetField{}), do: false

    @doc """
    Authenticated users who own the DataSetField's parent Meta are the only
    users able to access it.
    """
    def can?(%User{id: user_id}, _, %DataSetField{meta_id: meta_id}) do
      meta = MetaActions.get(meta_id)
      meta.user_id == user_id
    end

    @doc """
    Anonymous users have no access to VirtualDateField.
    """
    def can?(nil, _, %VirtualDateField{}), do: false

    @doc """
    Authenticated users who own the VirtualDateField's parent Meta are the only
    users able to access it.
    """
    def can?(%User{id: user_id}, _, %VirtualDateField{meta_id: meta_id}) do
      meta = MetaActions.get(meta_id)
      meta.user_id == user_id
    end

    @doc """
    Anonymous users have no access to VirtualPointField.
    """
    def can?(nil, _, %VirtualPointField{}), do: false

    @doc """
    Authenticated users who own the VirtualPointField's parent Meta are the only
    users able to access it.
    """
    def can?(%User{id: user_id}, _, %VirtualPointField{meta_id: meta_id}) do
      meta = MetaActions.get(meta_id)
      meta.user_id == user_id
    end

    @doc """
    Anonymous users have no access to UniqueConstraint.
    """
    def can?(nil, _, %UniqueConstraint{}), do: false

    @doc """
    Authenticated users who own the UniqueConstraint's parent Meta are the only
    users able to access it.
    """
    def can?(%User{id: user_id}, _, %UniqueConstraint{meta_id: meta_id}) do
      meta = MetaActions.get(meta_id)
      meta.user_id == user_id
    end

    @doc """
    Anonymous users can only access the User index and show.
    """
    def can?(nil, action, %User{}) when action in [:index, :show], do: true
    def can?(nil, _, %User{}), do: false

    @doc """
    Authenticated users can only access another User's index and show, unless
    they are the requested User -- then obviously they can do whatever with
    themselves... I mean it's a free country and all.
    """
    def can?(%User{id: user_id}, _, %User{id: user_id}), do: true
    def can?(%User{}, action, %User{}) when action in [:index, :show], do: true
    def can?(%User{}, _, %User{}), do: false
  end
end
