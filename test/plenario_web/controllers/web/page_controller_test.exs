defmodule PlenarioWeb.Web.Testing.PageControllerTest do
  use PlenarioWeb.Testing.ConnCase, async: true

  alias Plenario.Actions.{UserActions, MetaActions}

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
  test "search all data sets", %{conn: conn} do
    {:ok, user} = UserActions.create("name", "email@example.com", "password")
    {:ok, meta1} = MetaActions.create("name 1", user, "https://example.com/1", "csv")
    {:ok, meta2} = MetaActions.create("name 2", user, "https://example.com/2", "csv")
    {:ok, meta3} = MetaActions.create("name 3", user, "https://example.com/3", "csv")
    {:ok, meta4} = MetaActions.create("name 4", user, "https://example.com/4", "csv")

    bbox =
      %Geo.Polygon{
        coordinates: [
          [{30, 10}, {40, 40}, {20, 40}, {10, 20}, {30, 10}]
        ],
        srid: 4326
      }
    {_, lower, _} = DateTime.from_iso8601("2017-01-01T00:00:00.0Z")
    {_, upper, _} = DateTime.from_iso8601("2018-12-31T00:00:00.0Z")

    {:ok, _} = MetaActions.update_bbox(meta1, bbox)
    {:ok, _} = MetaActions.update_time_range(meta1, lower, upper)

    {:ok, _} = MetaActions.update_bbox(meta2, bbox)
    {:ok, _} = MetaActions.update_time_range(meta2, lower, upper)

    bbox =
      %Geo.Polygon{
        coordinates: [
          [{-30, -10}, {-40, -40}, {-20, -40}, {-10, -20}, {-30, -10}]
        ],
        srid: 4326
      }
    {_, lower, _} = DateTime.from_iso8601("2015-01-01T00:00:00.0Z")
    {_, upper, _} = DateTime.from_iso8601("2016-12-31T00:00:00.0Z")

    {:ok, _} = MetaActions.update_bbox(meta3, bbox)
    {:ok, _} = MetaActions.update_time_range(meta3, lower, upper)

    {:ok, _} = MetaActions.update_bbox(meta4, bbox)
    {:ok, _} = MetaActions.update_time_range(meta4, lower, upper)

    m = MetaActions.get(meta1.id)
    {:ok, _} = MetaActions.submit_for_approval(m)
    m = MetaActions.get(meta1.id)
    {:ok, _} = MetaActions.approve(m)
    m = MetaActions.get(meta1.id)
    {:ok, _} = MetaActions.mark_first_import(m)

    m = MetaActions.get(meta2.id)
    {:ok, _} = MetaActions.submit_for_approval(m)
    m = MetaActions.get(meta2.id)
    {:ok, _} = MetaActions.approve(m)
    m = MetaActions.get(meta2.id)
    {:ok, _} = MetaActions.mark_first_import(m)

    m = MetaActions.get(meta3.id)
    {:ok, _} = MetaActions.submit_for_approval(m)
    m = MetaActions.get(meta3.id)
    {:ok, _} = MetaActions.approve(m)
    m = MetaActions.get(meta3.id)
    {:ok, _} = MetaActions.mark_first_import(m)

    m = MetaActions.get(meta4.id)
    {:ok, _} = MetaActions.submit_for_approval(m)
    m = MetaActions.get(meta4.id)
    {:ok, _} = MetaActions.approve(m)
    m = MetaActions.get(meta4.id)
    {:ok, _} = MetaActions.mark_first_import(m)

    params = %{
      "starting_on" => "2014-11-01",
      "ending_on" => "2015-11-01",
      "coords" => "[[-30, -20], [-40, -50], [-10, -30], [-30, -20]]"
    }
    response =
      conn
      |> post(page_path(conn, :search_all_data_sets, params))
      |> html_response(:ok)

    refute response =~ meta1.name
    refute response =~ meta2.name
    assert response =~ meta3.name
    assert response =~ meta4.name

    params = %{
      "starting_on" => "2016-11-01",
      "ending_on" => "2017-11-01",
      "coords" => "[[30, 20], [40, 50], [10, 30], [30, 20]]"
    }
    response =
      conn
      |> post(page_path(conn, :search_all_data_sets, params))
      |> html_response(:ok)

    assert response =~ meta1.name
    assert response =~ meta2.name
    refute response =~ meta3.name
    refute response =~ meta4.name

    params = %{
      "starting_on" => "2014-11-01",
      "ending_on" => "2015-11-01",
      "coords" => "[[30, 20], [40, 50], [10, 30], [30, 20]]"
    }
    response =
      conn
      |> post(page_path(conn, :search_all_data_sets, params))
      |> html_response(:ok)

    refute response =~ meta1.name
    refute response =~ meta2.name
    refute response =~ meta3.name
    refute response =~ meta4.name
    assert response =~ "Sorry, we didn't find any data sets that matched your criteria"
  end

  @tag :anon
  test "aot_explorer", %{conn: conn} do
    conn
    |> get(page_path(conn, :aot_explorer))
    |> html_response(:ok)
  end
end
