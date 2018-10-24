defmodule PlenarioWeb.Web.Testing.PageControllerTest do
  use PlenarioWeb.Testing.ConnCase
  import PlenarioWeb.Router.Helpers

  setup do
    Plenario.ModelRegistry.clear()
  end

  @tag :anon
  test "index", %{conn: conn} do
    conn
    |> get(page_path(conn, :index))
    |> html_response(:ok)
  end

  @tag :anon
  test "explorer", %{conn: conn} do
    conn
    |> get(page_path(conn, :explorer))
    |> html_response(:ok)
  end

  @tag :anon
  test "explorer receives start datetime and end datetime", %{conn: conn} do
    params = %{
      "starting_on" => "2018-03-31",
      "ending_on" => "2018-05-01",
      "zoom" => 10,
      "coords" => "[[30, 20], [40, 50], [10, 30], [30, 20]]"
    }

    conn = get(conn, page_path(conn, :explorer), params)
    assert get_flash(conn)["error"] == nil
  end

  @tag :anon
  test "explorer receives start datetime greater than end datetime", %{conn: conn} do
    params = %{
      "starting_on" => "2018-05-01",
      "ending_on" => "2018-04-28",
      "zoom" => 10,
      "coords" => "[[30, 20], [40, 50], [10, 30], [30, 20]]"
    }

    conn = get(conn, page_path(conn, :explorer), params)
    assert get_flash(conn)["error"] =~ "You must select a time range with a starting date earlier than the ending date."
  end

  @tag :anon
  test "explorer receives a terribly formatted datetime", %{conn: conn} do
    conn = get(conn, page_path(conn, :explorer), %{
      "starting_on" => "woopwoop",
      "ending_on" => "2000-01-01",
      "coords" => "[[30, 20], [40, 50], [10, 30], [30, 20]]"
    })
    assert get_flash(conn)["error"] =~ "You must select a time range with a starting date earlier than the ending date."
  end
end
