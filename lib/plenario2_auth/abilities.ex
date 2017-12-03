defmodule Plenario2Auth.Abilities do
  alias Plenario2Auth.User
  alias Plenario2.Schemas.{Meta}

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
    def can?(nil, _, meta = %Meta{}), do: false
  end
end
