defmodule PlenarioEtl.Rows do
  @moduledoc """
  Functions for working with collections of rows.
  """

  @doc """
  Given two lists of rows, pair each of their elements by the keys provided 
  with `constraints`. This method is used to prep rows for diffing.

  ## Examples

      iex> rowset1 = [
      ...>   %{colA: 1, colB: 2, colC: "bar"}, 
      ...>   %{colA: 4, colB: 5, colC: "foo"}
      ...> ]
      iex> rowset2 = [
      ...>   %{colA: 4, colB: 5, colC: "bar"},
      ...>   %{colA: 1, colB: 2, colC: "foo"},
      ...>   %{colA: 7, colB: 7, colC: "foo"}
      ...> ]
      iex> PlenarioEtl.Rows.pair_rows(rowset1, rowset2, [:colA, :colB])
      [
        {
          %{colA: 1, colB: 2, colC: "bar"},
          %{colA: 1, colB: 2, colC: "foo"}
        },
        {
          %{colA: 4, colB: 5, colC: "foo"},
          %{colA: 4, colB: 5, colC: "bar"}
        }
      ]
      
  """
  @spec pair_rows(rowset1 :: list, rowset2 :: list, constraints :: list) :: list
  def pair_rows(rowset1, rowset2, constraints) do
    Enum.map(rowset1, fn row1 ->
      match = Enum.find(rowset2, fn row2 ->
        to_key(row1, constraints) == to_key(row2, constraints)
      end)

      {row1, match}
    end)
    |> Enum.filter(fn {row1, row2} ->
      !is_nil(row1) && !is_nil(row2)
    end)
  end

  @doc """
  Extract the constraint values into a tuple key for a row.

  ## Examples

      iex> row = %{colA: 1, colB: 2, colC: "bar"}
      iex> PlenarioEtl.Rows.to_key(row, [:colA, :colB])
      {1, 2}
      
  """
  @spec to_key(row :: list, constraints :: list) :: tuple
  def to_key(row, constraints) do
    List.to_tuple(for constraint <- constraints, do: Map.get(row, constraint))
  end
end
