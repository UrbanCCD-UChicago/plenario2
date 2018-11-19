defmodule Plenario.Testing.EtlTest do
  use Plenario.Testing.DataCase

  alias Plenario.{
    DataSetActions,
    Etl
  }

  describe "find_data_sets" do
    @tag :user
    test "should only return data sets ready to be imported", context do
      one = create_data_set(context, name: "one", src_url: "https://example.com/1")
      two = create_data_set(context, name: "two", src_url: "https://example.com/2")
      three = create_data_set(context, name: "three", src_url: "https://example.com/3")
      four = create_data_set(context, name: "four", src_url: "https://example.com/4")
      five = create_data_set(context, name: "five", src_url: "https://example.com/5")

      {:ok, _} = DataSetActions.update one,
        state: "ready",
        refresh_starts_on: "2018-01-01"

      {:ok, _} = DataSetActions.update two,
        state: "awaiting_first_import",
        refresh_starts_on: "2018-01-01"

      {:ok, _} = DataSetActions.update three,
        state: "ready",
        refresh_starts_on: "2018-01-01",
        refresh_ends_on: Timex.shift(NaiveDateTime.utc_now(), days: -1) |> Timex.to_date() |> Timex.format!("%Y-%m-%d", :strftime),
        next_import: Timex.shift(NaiveDateTime.utc_now(), days: -1)

      {:ok, _} = DataSetActions.update four,
        state: "erred",
        refresh_starts_on: "2018-01-01",
        next_import: NaiveDateTime.utc_now()

      {:ok, _} = DataSetActions.update five,
        state: "ready",
        refresh_starts_on: "2018-01-01",
        next_import: Timex.shift(NaiveDateTime.utc_now(), days: 1)

      importable = Etl.find_data_sets()
      assert length(importable) == 2

      ids = Enum.map(importable, & &1.id)

      [one.id, two.id]
      |> Enum.each(& assert Enum.member?(ids, &1))
    end
  end
end
