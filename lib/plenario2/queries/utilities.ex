defmodule Plenario2.Queries.Utilities do
  @moduledoc """
  Functions for working with query composition
  """

  @doc """
  Checks the thruthiness of the :condition and if it's true then
  it applies the :module and :function to the :query.

  ## Examples

    iex> {_, vince} = UserActions.get_from_email("vince@example.com")
    iex> opts = [with_fields: true, with_user: true, with_diffs: false, for_vince: true]
    iex> MetaQueries.list()
         |> cond_compose(opts[:with_fields], MetaQueries, :with_fields)
         |> cond_compose(opts[:with_user], MetaQueries, :with_user)
         |> cond_compose(opts[:with_diffs], MetaQueries, :with_diffs)
    {:ok, [
      %Meta{name: "one", user: %User{name: "vince", ...}, data_set_fields: [%DataSetField{...}, ...], ...},
      %Meta{name: "two", user: %User{name: "jesse", ...}, data_set_fields: [%DataSetField{...}, ...], ...},
    ]}
  """
  def cond_compose(query, condition, module, function) do
    if condition do
      apply(module, function, [query])
    else
      query
    end
  end
end
