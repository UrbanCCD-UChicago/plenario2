defmodule Plenario.Queries.Utils do

  @doc """
  Creates a fragment that applied the Postgres timestamptz range interset.
  """
  defmacro tstzrange_intersects(meta_tstzrange, filter_tstzrange) do
    quote do: fragment("?::tstzrange && ?::tstzrange", unquote(meta_tstzrange), unquote(filter_tstzrange))
  end

  @doc """
  Conditionally composes an Ecto Query when the given condition is truthy
  applying the function available at module/function.

  ## Example

    from(u in User)
    |> bool_compose(some_testable_value, UserQueries, :is_active?)
  """
  @spec bool_compose(Ecto.Queryable.t, boolean, module, atom) :: Ecto.Queryable.t
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
  @spec filter_compose(Ecto.Queryable.t, any, module, atom) :: Ecto.Queryable.t
  def filter_compose(query, value, module, function) do
    if value != :dont_use_me do
      apply(module, function, [query, value])
    else
      query
    end
  end
end
