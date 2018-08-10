defmodule Plenario.Queries.Utils do
  @doc """
  Creates a fragment that applied the Postgres timestamp range interset.
  """
  defmacro tsrange_intersects(meta_tsrange, filter_tsrange) do
    quote do: fragment("?::tsrange && ?::tsrange", unquote(meta_tsrange), unquote(filter_tsrange))
  end

  defmacro timestamp_within(field, range) do
    quote do: fragment("?::timestamp <@ ?::tsrange", unquote(field), unquote(range))
  end

  defmacro tsrange_contains_timestamp(field, date) do
    quote do: fragment("?::tsrange @> ?::timestamp", unquote(field), unquote(date))
  end

  @doc """
  Conditionally composes an Ecto Query when the given condition is truthy
  applying the function available at module/function.

  ## Example

    from(u in User)
    |> bool_compose(some_testable_value, UserQueries, :is_active?)
  """
  @spec bool_compose(Ecto.Queryable.t(), boolean, module, atom) :: Ecto.Queryable.t()
  def bool_compose(query, condition, module, function) do
    if condition do
      apply(module, function, [query])
    else
      query
    end
  end

  @doc """
  Conditionally composes an Ecto Query when the given value is not equal to the
  pass atom :dont_use_me applying the function available at module/function.

  ## Example

    from(u in User)
    |> filter_compose("test@example.com", UserQueries, :get)
  """
  @spec filter_compose(Ecto.Queryable.t(), any, module, atom) :: Ecto.Queryable.t()
  def filter_compose(query, value, module, function) do
    if value != :dont_use_me do
      apply(module, function, [query, value])
    else
      query
    end
  end
end
