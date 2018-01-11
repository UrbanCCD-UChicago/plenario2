defmodule Plenario2Etl.Rows do
  @moduledoc """
  Functions for working with collections of rows.
  """

  @doc """
  Convert a list of lists to a list of keyword lists.

  ## Examples

      iex> import Plenario2Etl.Rows
      iex> rows = [[1, 2, 3], [4, 5, 6]]
      iex> to_kwlist(rows, [:colA, :colB, :colC])
      [[colA: 1, colB: 2, colC: 3], [colA: 4, colB: 5, colC: 6]]

  """
  @spec to_kwlist(rows :: list, columns :: list) :: list
  def to_kwlist(rows, columns) do
    Enum.map(rows, fn row ->
      Enum.zip(columns, row)
    end)
  end

  @doc """
  Given two lists of rows, pair each of their elements by the keys provided 
  with `constraints`. This method is used to prep rows for diffing.

  ## Examples

      iex> rowset1 = [
      ...>   [colA: 1, colB: 2, colC: "bar"], 
      ...>   [colA: 4, colB: 5, colC: "foo"]
      ...> ]
      iex> rowset2 = [
      ...>   [colA: 4, colB: 5, colC: "bar"], 
      ...>   [colA: 1, colB: 2, colC: "foo"],
      ...>   [colA: 7, colB: 7, colC: "foo"]
      ...> ]
      iex> Plenario2Etl.Rows.pair_rows(rowset1, rowset2, [:colA, :colB])
      [
        {
          [colA: 1, colB: 2, colC: "bar"],
          [colA: 1, colB: 2, colC: "foo"]
        },
        {
          [colA: 4, colB: 5, colC: "foo"],
          [colA: 4, colB: 5, colC: "bar"]
        }
      ]
      
  """
  @spec pair_rows(rowset1 :: list, rowset2 :: list, constraints :: list) :: list
  def pair_rows(rowset1, rowset2, constraints) do
    valid_keys = Enum.map(rowset1, &to_key(&1, constraints))
    valid_rows = Enum.filter(rowset2, &(to_key(&1, constraints) in valid_keys))

    Enum.zip([Enum.sort(rowset1), Enum.sort(valid_rows)])
  end

  @doc """
  Extract the constraint values into a tuple key for a row.

  ## Examples

      iex> row = [colA: 1, colB: 2, colC: "bar"]
      iex> Plenario2Etl.Rows.to_key(row, [:colA, :colB])
      {1, 2}
      
  """
  @spec to_key(row :: list, constraints :: list) :: tuple
  def to_key(row, constraints) do
    List.to_tuple(for constraint <- constraints, do: row[constraint])
  end
end
