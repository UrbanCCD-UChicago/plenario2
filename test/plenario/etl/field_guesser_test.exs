defmodule Plenario.Testig.FieldGuesserTest do
  use ExUnit.Case, async: true

  alias Plenario.Etl.FieldGuesser

  test :boolean? do
    assert FieldGuesser.boolean? true
    assert FieldGuesser.boolean? false
    assert FieldGuesser.boolean? "true"
    assert FieldGuesser.boolean? "false"
    assert FieldGuesser.boolean? "t"
    assert FieldGuesser.boolean? "f"
    assert FieldGuesser.boolean? "TRUE"
    assert FieldGuesser.boolean? "FALSE"
    assert FieldGuesser.boolean? "T"
    assert FieldGuesser.boolean? "F"

    refute FieldGuesser.boolean? "negative"
    refute FieldGuesser.boolean? "affirmative"
    refute FieldGuesser.boolean? "sure. why not?"
  end

  test :integer? do
    assert FieldGuesser.integer? 42
    assert FieldGuesser.integer? -42
    assert FieldGuesser.integer? "42"
    assert FieldGuesser.integer? "-42"

    refute FieldGuesser.integer? 42.0
    refute FieldGuesser.integer? -42.0
    refute FieldGuesser.integer? "42.0"
    refute FieldGuesser.integer? "-42.0"
  end

  test :float? do
    assert FieldGuesser.float? 42.0
    assert FieldGuesser.float? -42.0
    assert FieldGuesser.float? "42.0"
    assert FieldGuesser.float? "-42.0"

    refute FieldGuesser.float? 42
    refute FieldGuesser.float? -42
    refute FieldGuesser.float? "42"
    refute FieldGuesser.float? "-42"
  end

  test :date? do
    # iso basic
    assert FieldGuesser.date? "2018-04-21T15:00:00-0500"
    # iso basic z
    assert FieldGuesser.date? "20180421T200000Z"
    # iso extended
    assert FieldGuesser.date? "2018-04-21T15:00:00-05:00"
    # iso extended z
    assert FieldGuesser.date? "2018-04-21T20:00:00Z"
    # mm/dd/yyyy
    assert FieldGuesser.date? "4/21/2018"
    assert FieldGuesser.date? "04/21/2018"
    # mm/dd/yyyy h12:m:s a
    assert FieldGuesser.date? "4/21/2018 3:00:00 PM"
    assert FieldGuesser.date? "4/21/2018 03:00:00 PM"
    assert FieldGuesser.date? "04/21/2018 03:00:00 PM"

    # all other formats will fail... sorry
    refute FieldGuesser.date? "31/10/2018"
  end

  test :geometry? do
    assert FieldGuesser.geometry? "POINT(1 2)"
    assert FieldGuesser.geometry? "MULTIPOINT(1 2)"
    assert FieldGuesser.geometry? "POLYGON ((1 1, 1 2, 2 2, 2 1, 1 1))"

    refute FieldGuesser.geometry? "square"
  end

  test :json? do
    assert FieldGuesser.json? "{}"
    assert FieldGuesser.json? "[]"
    assert FieldGuesser.json? "[{\"one\": \"two\"}]"

    refute FieldGuesser.json? "text"
  end
end



