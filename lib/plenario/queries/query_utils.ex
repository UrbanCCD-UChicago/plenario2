defmodule Plenario.QueryUtils do
  import Ecto.Query

  @doc """
  Genreically applies ordering. This should be delegated to from the query modules.
  """
  @spec order(Ecto.Queryable.t(), {:asc | :desc, atom()}) :: Ecto.Queryable.t()
  def order(query, {dir, fname}) do
    case Enum.empty?(query.order_bys) do
      true -> do_order(query, dir, fname)
      false -> query
    end
  end

  defp do_order(query, :asc, fname) do
    case Enum.empty?(query.group_bys) do
      true ->
        order_by(query, [q], asc: ^fname)

      false ->
        order_by(query, [q], asc: ^fname)
        |> group_by(^fname)
    end
  end

  defp do_order(query, :desc, fname) do
    case Enum.empty?(query.group_bys) do
      true ->
        order_by(query, [q], desc: ^fname)

      false ->
        order_by(query, [q], desc: ^fname)
        |> group_by(^fname)
    end
  end

  @doc """
  Generically applies pagination. This should be delegated to from the query modules.
  """
  @spec paginate(Ecto.Queryable.t(), {pos_integer(), pos_integer()}) :: Ecto.Queryable.t() | no_return()
  def paginate(query, {page, size}) do
    cond do
      !is_integer(page) or page < 1 -> raise "page must be a non-negative integer"
      !is_integer(size) or size < 1 -> raise "size must be a non-negative integer"
      true -> :ok
    end

    starting_at = (page - 1) * size

    query
    |> offset(^starting_at)
    |> limit(^size)
  end

  @doc """
  Applies the given `module.func` to the query if the flag is true, otherwise it
  simply returns the query unmodified.
  """
  @spec boolean_compose(Ecto.Queryable.t(), boolean(), module(), atom()) :: Ecto.Queryable.t()
  def boolean_compose(query, false, _module, _func), do: query
  def boolean_compose(query, true, module, func), do: apply(module, func, [query])

  @doc """
  Applies the given `module.func` to the query with the given `value` as the parameter
  to the function if the value is not :empty, otherwise it returns the query unmodified.
  """
  @spec filter_compose(Ecto.Queryable.t(), :empty | any(), module(), atom()) :: Ecto.Queryable.t()
  def filter_compose(query, :empty, _module, _func), do: query
def filter_compose(query, value, module, func), do: apply(module, func, [query, value])
end
