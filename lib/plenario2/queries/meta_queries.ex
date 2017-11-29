defmodule Plenario2.Queries.MetaQueries do
  import Ecto.Query
  alias Plenario2.Schemas.Meta

  def from_slug(slug), do: (from m in Meta, where: m.slug == ^slug)

  def list(), do: (from m in Meta)

  def with_user(query), do: from m in query, preload: [user: :metas]

  # def with_data_set_fields(query), do: from m in query, preload: [data_set_fields: :metas]
  #
  # def with_data_set_constraints(query), do: from m in query, preload: [data_set_constraints: :metas]
  #
  # def with_virtual_date_fields(query), do: from m in query, preload: [virtual_date_fields: :metas]
  #
  # def with_virtual_point_fields(query), do: from m in query, preload: [virtual_point_fields: :metas]
  #
  # def with_data_set_diffs(query), do: from m in query, preload: [data_set_diffs: :metas]
end
