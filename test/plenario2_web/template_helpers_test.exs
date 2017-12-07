defmodule Plenario2Web.TemplateHelpersTest do
  use ExUnit.Case, asnc: true

  import Plenario2Web.TemplateHelpers

  describe ":s_plural" do
    test "with 1" do
      assert s_plural("Data Set", 1) == "Data Set"
    end

    test "with not 1" do
      assert s_plural("Data Set", 2) == "Data Sets"
      assert s_plural("Data Set", 0) == "Data Sets"
    end
  end

  describe ":es_plural" do
    test "with 1" do
      assert es_plural("Crash", 1) == "Crash"
    end

    test "with not 1" do
      assert es_plural("Crash", 2) == "Crashes"
      assert es_plural("Crash", 0) == "Crashes"
    end
  end

  describe ":irregular_plural" do
    test "with 1" do
      assert irregular_plural("Man", "Men", 1) == "Man"
    end

    test "with not 1" do
      assert irregular_plural("Woman", "Women", 2) == "Women"
      assert irregular_plural("Woman", "Women", 0) == "Women"
    end
  end
end
