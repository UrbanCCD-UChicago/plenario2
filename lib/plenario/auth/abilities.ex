defmodule Plenario.Auth.Abilities do
  alias Plenario.{
    DataSet,
    DataSetActions,
    Field,
    User,
    VirtualDate,
    VirtualPoint
  }

  # Anonymous users

  defimpl Canada.Can, for: Atom do
    def can?(nil, action, User) when action in [:new, :index, :create], do: true
    def can?(nil, :show, %User{}), do: true

    def can?(nil, :index, DataSet), do: true
    def can?(nil, :show, %DataSet{}), do: true

    # disallow all other actions
    def can?(nil, _, _), do: false
  end

  # Authenticated users

  defimpl Canada.Can, for: User do
    # Admins can do whatever they want
    def can?(%User{is_admin?: true}, _, _), do: true

    # Regular users have authorization realms
    def can?(%User{}, action, DataSet) when action in [:new, :index, :create], do: true
    def can?(%User{id: id}, _, %DataSet{user_id: id}), do: true

    def can?(%User{}, action, Field) when action in [:new, :create], do: true
    def can?(%User{id: uid}, _, %Field{data_set_id: dsid}), do: owns_parent?(uid, dsid)

    def can?(%User{}, action, VirtualDate) when action in [:new, :create], do: true
    def can?(%User{id: uid}, _, %VirtualDate{data_set_id: dsid}), do: owns_parent?(uid, dsid)

    def can?(%User{}, action, VirtualPoint) when action in [:new, :create], do: true
    def can?(%User{id: uid}, _, %VirtualPoint{data_set_id: dsid}), do: owns_parent?(uid, dsid)

    def can?(%User{}, _, _), do: false

    # helper
    defp owns_parent?(user_id, data_set_id) do
      data_set = DataSetActions.get!(data_set_id)
      data_set.user_id == user_id
    end
  end
end
