defmodule Plenario2.Queries.MetaQueries do
  import Ecto.Query
  import Plenario2.Queries.Utils
  alias Plenario2.Queries.MetaQueries
  alias Plenario2.Schemas.Meta

  ##
  # one

  def from_id(id), do: (from m in Meta, where: m.id == ^id)

  def from_slug(slug), do: (from m in Meta, where: m.slug == ^slug)

  ##
  # all

  def list(), do: (from m in Meta)

  ##
  # preloads

  def with_user(query), do: from m in query, preload: [user: :metas]

  def with_data_set_fields(query), do: from m in query, preload: [data_set_fields: :meta]

  def with_data_set_constraints(query), do: from m in query, preload: [data_set_constraints: :metas]

  def with_virtual_date_fields(query), do: from m in query, preload: [virtual_date_fields: :metas]

  def with_virtual_point_fields(query), do: from m in query, preload: [virtual_point_fields: :metas]

  def with_data_set_diffs(query), do: from m in query, preload: [data_set_diffs: :metas]

  def with_admin_user_notes(query), do: from m in query, preload: [admin_user_notes: :meta]

  ##
  # filters

  def new(query), do: from m in query, where: m.state == "new"

  def needs_approval(query), do: from m in query, where: m.state == "needs_approval"

  def ready(query), do: from m in query, where: m.state == "ready"

  def erred(query), do: from m in query, where: m.state == "erred"

  def limit_to(query, limit), do: from m in query, limit: ^limit

  def for_user(query, user), do: from m in query, where: m.user_id == ^user.id

  ##
  # handle query options
  def handle_opts(query, opts \\ []) do
    defaults = [
      with_user: false,
      with_fields: false,
      with_virtual_dates: false,
      with_virtual_points: false,
      with_constraints: false,
      with_diffs: false,
      with_notes: false,
      new: false,
      needs_approval: false,
      ready: false,
      erred: false,
      limit_to: nil,
      for_user: nil
    ]
    opts = Keyword.merge(defaults, opts)

    query
    |> cond_compose(opts[:with_user], MetaQueries, :with_user)
    |> cond_compose(opts[:with_fields], MetaQueries, :with_data_set_fields)
    |> cond_compose(opts[:with_virtual_dates], MetaQueries, :with_virtual_date_fields)
    |> cond_compose(opts[:with_virtual_points], MetaQueries, :with_virtual_point_fields)
    |> cond_compose(opts[:with_constraints], MetaQueries, :with_data_set_constraints)
    |> cond_compose(opts[:with_diffs], MetaQueries, :with_data_set_diffs)
    |> cond_compose(opts[:with_notes], MetaQueries, :with_admin_user_notes)
    |> cond_compose(opts[:new], MetaQueries, :new)
    |> cond_compose(opts[:needs_approval], MetaQueries, :needs_approval)
    |> cond_compose(opts[:ready], MetaQueries, :ready)
    |> cond_compose(opts[:erred], MetaQueries, :erred)
    |> filter_compose(opts[:limit_to], MetaQueries, :limit_to)
    |> filter_compose(opts[:for_user], MetaQueries, :for_user)
  end
end
