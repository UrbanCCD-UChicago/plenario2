defmodule Plenario2Etl.Rows do
  @moduledoc """
  Functions for working with collections of rows.
  """

  @doc """
  Convert a list of lists to a list of keyword lists.

  ## Examples

      iex> import Plenario2Etl.Rows
      iex> rows = [[1, 2, 3], [4, 5, 6]]
      iex> to_kwlists(rows, [:colA, :colB, :colC])
      [[colA: 1, colB: 2, colC: 3], [colA: 4, colB: 5, colC: 6]]

  """
  @spec to_kwlists(rows :: list, columns :: list) :: list
  def to_kwlists(rows, columns) do
    Enum.map(rows, fn row ->
      Enum.zip(columns, row)
    end)
  end

  @doc """
  Convert a list of tuples where the first element is a string to
  a keyword list.

  ## Examples

      iex> import Plenario2Etl.Rows
      iex> row = [{"date ", "foo"}, {" address", "bar"}]
      iex> to_kwlist_from_tuples(row)
      [date: "foo", address: "bar"]

  """
  def to_kwlist_from_tuples(row) do
    for {k, v} <- row do
      {String.to_atom(Slug.slugify(k, separator: ?_)), v}
    end
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

  @doc """
  Select a subset of a `row`'s values using the keys provided by `columns`.

  ## Examples

      iex> row = [colA: 1, colB: 2, colC: "bar"]
      iex> Plenario2Etl.Rows.select_columns(row, [:colA, :colC])
      [colA: 1, colC: "bar"]

  """
  @spec select_columns(row :: list, columns :: list) :: list
  def select_columns(row, columns) do
    for column <- columns, do: {column, row[column]}
  end

  @doc """
  Prepare a row value for insertion into the database. Handles escaping.

  ## Examples

      iex> row = [nil, "'", "\\"", "--", 10]
      iex> Enum.map(row, &Plenario2Etl.Rows.escape/1)
      ["null", "'&#39;'", "'&quot;'", "'--'", 10]

  """
  def escape(v) when is_binary(v) do
    {:safe, safe} = Phoenix.HTML.html_escape(v)
    "'#{safe}'"
  end

  def escape(v) when is_nil(v), do: "null"
  def escape(v), do: v
end
