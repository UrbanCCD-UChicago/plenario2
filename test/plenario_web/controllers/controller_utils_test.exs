defmodule PlenarioWeb.Testing.ControllerUtilsTest do
  use Plenario.Testing.DataCase, async: true

  alias PlenarioWeb.Controllers.Utils

  test "YYYY-MM-DD" do
    result = Utils.parse_date_string("2018-01-01")
    assert result == "2018-01-01"
  end

  test "MM/DD/YYY" do
    result = Utils.parse_date_string("01/01/2018")
    assert result == "2018-01-01"
    result = Utils.parse_date_string("1/1/2018")
    assert result == "2018-01-01"
  end

  test "DD/MM/YYYY" do
    result = Utils.parse_date_string("31/12/2018")
    assert result == "2018-12-31"
  end

  test "something that doesn't parse" do
    result = Utils.parse_date_string("whenever")
    assert ^result = Timex.format!(Timex.today(), "{YYYY}-{0M}-{0D}")
  end
end
