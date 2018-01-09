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
  def to_kwlist(rows, columns) do
    Enum.map(rows, fn row -> 
        Enum.zip(columns, row) 
    end)
  end
end
