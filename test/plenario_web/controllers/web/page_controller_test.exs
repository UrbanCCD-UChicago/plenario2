defmodule PlenarioWeb.Web.Testing.PageControllerTest do
  use PlenarioWeb.Testing.ConnCase
  import PlenarioWeb.Router.Helpers

  alias Plenario.Actions.{
    UserActions,
    MetaActions,
    DataSetFieldActions,
    VirtualPointFieldActions
  }

  alias PlenarioAot.AotActions

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
  test "search explorer", %{conn: conn} do
    {:ok, user} = UserActions.create("name", "email@example.com", "password")
    {:ok, meta1} = MetaActions.create("name 1", user, "https://example.com/1", "csv")
    {:ok, meta2} = MetaActions.create("name 2", user, "https://example.com/2", "csv")
    {:ok, meta3} = MetaActions.create("name 3", user, "https://example.com/3", "csv")
    {:ok, meta4} = MetaActions.create("name 4", user, "https://example.com/4", "csv")

    for meta <- [meta1, meta2, meta3, meta4] do
      {:ok, _} = DataSetFieldActions.create(meta, "id", "integer")
      {:ok, _} = DataSetFieldActions.create(meta, "timestamp", "timestamp")
      {:ok, _} = DataSetFieldActions.create(meta, "observation", "float")
      {:ok, f} = DataSetFieldActions.create(meta, "location", "text")
      {:ok, _} = VirtualPointFieldActions.create(meta, f.id)
    end

    bbox =
      %Geo.Polygon{
        coordinates: [
          [{30, 10}, {40, 40}, {20, 40}, {10, 20}, {30, 10}]
        ],
        srid: 4326
      }
    {_, lower} = NaiveDateTime.from_iso8601("2017-01-01T00:00:00.0")
    {_, upper} = NaiveDateTime.from_iso8601("2018-12-31T00:00:00.0")

    {:ok, _} = MetaActions.update_bbox(meta1, bbox)
    {:ok, _} = MetaActions.update_time_range(meta1, Plenario.TsRange.new(lower, upper))

    {:ok, _} = MetaActions.update_bbox(meta2, bbox)
    {:ok, _} = MetaActions.update_time_range(meta2, Plenario.TsRange.new(lower, upper))

    bbox =
      %Geo.Polygon{
        coordinates: [
          [{-30, -10}, {-40, -40}, {-20, -40}, {-10, -20}, {-30, -10}]
        ],
        srid: 4326
      }
    {_, lower} = NaiveDateTime.from_iso8601("2015-01-01T00:00:00.0")
    {_, upper} = NaiveDateTime.from_iso8601("2016-12-31T00:00:00.0")

    {:ok, _} = MetaActions.update_bbox(meta3, bbox)
    {:ok, _} = MetaActions.update_time_range(meta3, Plenario.TsRange.new(lower, upper))

    {:ok, _} = MetaActions.update_bbox(meta4, bbox)
    {:ok, _} = MetaActions.update_time_range(meta4, Plenario.TsRange.new(lower, upper))

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
      "coords" => Poison.encode!(%{
        _southWest: %{
          lat: -10,
          lng: -20
        },
        _northEast: %{
          lat: -40,
          lng: -50
        }
      }),
      "zoom" => 10
    }
    response =
      conn
      |> get(page_path(conn, :explorer, params))
      |> html_response(:ok)

    refute response =~ meta1.name
    refute response =~ meta2.name
    assert response =~ meta3.name
    assert response =~ meta4.name

    params = %{
      "starting_on" => "2016-11-01",
      "ending_on" => "2017-11-01",
      "coords" => Poison.encode!(%{
        _southWest: %{
          lat: 10,
          lng: 20
        },
        _northEast: %{
          lat: 40,
          lng: 50
        }
      }),
      "zoom" => 10
    }
    response =
      conn
      |> get(page_path(conn, :explorer, params))
      |> html_response(:ok)

    assert response =~ meta1.name
    assert response =~ meta2.name
    refute response =~ meta3.name
    refute response =~ meta4.name

    params = %{
      "starting_on" => "2014-11-01",
      "ending_on" => "2015-11-01",
      "coords" => Poison.encode!(%{
        _southWest: %{
          lat: 10,
          lng: 20
        },
        _northEast: %{
          lat: 40,
          lng: 50
        }
      }),
      "zoom" => 10
    }
    response =
      conn
      |> get(page_path(conn, :explorer, params))
      |> html_response(:ok)

    refute response =~ meta1.name
    refute response =~ meta2.name
    refute response =~ meta3.name
    refute response =~ meta4.name
    assert response =~ "Sorry, we didn't find any data sets that matched your criteria"
  end

  @tag :anon
  test "aot_explorer", %{conn: conn} do
    AotActions.create_meta("Chicago", "https://example.com/")

    conn
    |> get(page_path(conn, :aot_explorer))
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
