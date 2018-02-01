defmodule PlenarioAuth.Abilities do
  @moduledoc """
  Defines auhtorization capabilities for users in relation to resources. For example, we only
  want the user who owns a meta to be able to edit it.
  """

  alias Plenario.Schemas.{Meta, User}

  defimpl Canada.Can, for: User do
    @doc """
    For all modification actions, ensure the current user is the owner.
    """
    def can?(%User{id: user_id}, _, meta = %Meta{}) do
      meta.user_id == user_id
    end

    @doc """
    Forbid unauthenticated users from performing modification actions.
    """
    def can?(nil, _, _ = %Meta{}), do: false
  end
end
