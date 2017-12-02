defmodule Plenario2.Queries.Utils do
  @moduledoc """
  Functions for working with query composition
  """

  @doc """
  Checks the thruthiness of the :condition and if it's true then
  it applies the :module and :function to the :query.

  ## Examples

    iex> {_, vince} = UserActions.get_from_email("vince@example.com")
    iex> opts = [with_fields: true, with_user: true, with_diffs: false]
    iex> MetaQueries.list()
         |> cond_compose(opts[:with_fields], MetaQueries, :with_fields)
         |> cond_compose(opts[:with_user], MetaQueries, :with_user)
         |> cond_compose(opts[:with_diffs], MetaQueries, :with_diffs)
    [
      %Meta{name: "one", user: %User{name: "vince", ...}, data_set_fields: [%DataSetField{...}, ...], ...},
      %Meta{name: "two", user: %User{name: "jesse", ...}, data_set_fields: [%DataSetField{...}, ...], ...},
    ]
  """
  def cond_compose(query, condition, module, function) do
    if condition do
      apply(module, function, [query])
    else
      query
    end
  end

  @doc """
  Checks if the :value is not nil and then uses it to apply a given filter
  from :module and :function.

  ## Examples

    iex> {_, vince} = UserActions.get_from_email("vince@example.com"}
    iex> opts = [for_user: vince, with_user: true]
    iex> MetaQueries.list()
         |> filter_compose(opts[:for_user], MetaQueries, :for_user)
         |> cond_compose(opts[:with_user], MetaQueries, :with_user)
    [
      %Meta{name: "one", user: %User{name: "Vince", ...}, ...},
      %Meta{name: "two", user: %User{name: "Vince", ...}, ...},
    ]
  """
  def filter_compose(query, value, module, function) do
    if value != nil do
      apply(module, function, [query, value])
    else
      query
    end
  end
end
