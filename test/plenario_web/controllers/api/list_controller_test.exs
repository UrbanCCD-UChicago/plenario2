defmodule PlenarioWeb.Api.ListControllerTest do
  use PlenarioWeb.Testing.ConnCase

  alias Plenario.Actions.UserActions
  alias Plenario.Schemas.Meta
  alias Plenario.Repo

  @seattle_geojson """
    {
      "type": "Polygon",
      "coordinates": [
        [
          [
            -122.3169708251953,
            47.601591191496844
          ],
          [
            -122.3027229309082,
            47.601591191496844
          ],
          [
            -122.3027229309082,
            47.60627878178091
          ],
          [
            -122.3169708251953,
            47.60627878178091
          ],
          [
            -122.3169708251953,
            47.601591191496844
          ]
        ]
      ]
    }
    """
  
  @chicago_geojson """
    {
      "type": "Polygon",
      "coordinates": [
        [
          [
            -87.67776489257812,
            41.785649068644375
          ],
          [
            -87.59468078613281,
            41.785649068644375
          ],
          [
            -87.59468078613281,
            41.90585436043303
          ],
          [
            -87.67776489257812,
            41.90585436043303
          ],
          [
            -87.67776489257812,
            41.785649068644375
          ]
        ]
      ]
    }
    """

  setup do
    Ecto.Adapters.SQL.Sandbox.checkout(Plenario.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Plenario.Repo, {:shared, self()})

    {:ok, user} = UserActions.create("API Test User", "test@example.com", "password")
    seattle_geom = @seattle_geojson |> Poison.decode!() |> Geo.JSON.decode()
    chicago_geom = @chicago_geojson |> Poison.decode!() |> Geo.JSON.decode()

    (1..3) |> Enum.each(fn i ->
      Repo.insert(%{Meta.__struct__ | 
        user: user, 
        name: "API Test Dataset #{i}",
        slug: "api_test_dataset_#{i}",
        table_name: "ds_wootyhooty_#{i}",
        source_url: "https://www.example.com/#{i}", 
        source_type: "csv",
        bbox: %{seattle_geom | srid: 4326}
      })
    end)

    (4..5) |> Enum.each(fn i ->
      Repo.insert(%{Meta.__struct__ | 
        user: user, 
        name: "API Test Dataset #{i}",
        slug: "api_test_dataset_#{i}",
        table_name: "ds_wootyhooty_#{i}",
        source_url: "https://www.example.com/#{i}", 
        source_type: "csv",
        bbox: %{chicago_geom | srid: 4326}
      })
    end)

    :ok
  end

  test "GET /api/v2/data-sets", %{conn: conn} do
    conn = get(conn, "/api/v2/data-sets")
    result = json_response(conn, 200)
    assert length(result["data"]) == 5
  end

  test "GET /api/v2/data-sets/@head", %{conn: conn} do
    conn = get(conn, "/api/v2/data-sets/@head")
    result = json_response(conn, 200)
    assert is_map(result["data"])
  end

  test "GET /api/v2/data-sets/@describe", %{conn: conn} do
    conn = get(conn, "/api/v2/data-sets/@describe")
    result = json_response(conn, 200)
    assert length(result["data"]) == 5
  end

  test "OPTIONS /api/v2/data-sets status", %{conn: conn} do
    conn = options(conn, "/api/v2/data-sets")
    assert conn.status == 204
  end

  test "OPTIONS /api/v2/data-sets headers", %{conn: conn} do
    conn = options(conn, "/api/v2/data-sets")
    headers = Enum.into(conn.resp_headers, %{})
    assert headers["access-control-allow-methods"] == "GET,HEAD,OPTIONS"
    assert headers["access-control-allow-origin"] == "*"
    assert headers["access-control-max-age"] == "300"
  end

  test "GET /api/v2/data-sets with bbox arg", %{conn: conn} do
    conn = get(conn, "/api/v2/data-sets?bbox=#{@seattle_geojson}")
    result = json_response(conn, 200)
    assert length(result["data"]) == 3
  end

  test "GET /api/v2/data-sets/@describe with bbox arg", %{conn: conn} do
    conn = get(conn, "/api/v2/data-sets/@describe?bbox=#{@chicago_geojson}")
    result = json_response(conn, 200)
    assert length(result["data"]) == 2
  end
end
