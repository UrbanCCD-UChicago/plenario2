defmodule Plenario2.Queries.AdminUserNoteQueries do
  import Ecto.Query
  import Plenario2.Queries.Utils

  alias Plenario2.Schemas.AdminUserNote
  alias Plenario2.Queries.AdminUserNoteQueries

  def from_id(id), do: (from n in AdminUserNote, where: n.id == ^id)

  def list(), do: (from n in AdminUserNote)

  def unread(query), do: from n in query, where: n.acknowledged == false

  def acknowledged(query), do: from n in query, where: n.acknowledged == true

  def for_user(query, user), do: from n in query, where: n.user_id == ^user.id

  def oldest_first(query), do: from n in query, order_by: [desc: n.inserted_at]

  def handle_opts(query, opts \\ []) do
    defaults = [
      unread: false,
      acknowledged: false,
      for_user: nil,
      oldest: false
    ]
    opts = Keyword.merge(defaults, opts)

    query
    |> cond_compose(opts[:unread], AdminUserNoteQueries, :unread)
    |> cond_compose(opts[:acknowledged], AdminUserNoteQueries, :acknowledged)
    |> cond_compose(opts[:oldest_first], AdminUserNoteQueries, :oldest_first)
    |> filter_compose(opts[:for_user], AdminUserNoteQueries, :for_user)
  end
end
