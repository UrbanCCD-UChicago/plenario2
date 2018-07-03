defmodule PlenarioWeb.Api.ListControllerTest do
  use ExUnit.Case
  use Phoenix.ConnTest

  alias Plenario.Actions.{UserActions, MetaActions}

  @endpoint PlenarioWeb.Endpoint

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

    {:ok, chi_1} = MetaActions.create("API Test Dataset 1", user, "https://www.example.com/1", "csv")
    {:ok, chi_2} = MetaActions.create("API Test Dataset 2", user, "https://www.example.com/2", "csv")
    {:ok, chi_3} = MetaActions.create("API Test Dataset 3", user, "https://www.example.com/3", "csv")
    {:ok, sea_1} = MetaActions.create("API Test Dataset 4", user, "https://www.example.com/4", "csv")
    {:ok, sea_2} = MetaActions.create("API Test Dataset 5", user, "https://www.example.com/5", "csv")
    {:ok, sea_3} = MetaActions.create("API Test Dataset 6", user, "https://www.example.com/6", "csv")

    for meta <- [chi_1, chi_2, chi_3] do
      {:ok, _} = MetaActions.update(meta, bbox: %{chicago_geom | srid: 4326})
    end

    for meta <- [sea_1, sea_2, sea_3] do
      {:ok, _} = MetaActions.update(meta, bbox: %{seattle_geom | srid: 4326})
    end

    %{conn: build_conn()}
  end

  test "GET /api/v2/data-sets", %{conn: conn} do
    conn = get(conn, "/api/v2/data-sets")
    result = json_response(conn, 200)
    assert length(result["data"]) == 6
  end

  test "GET /api/v2/data-sets/@head", %{conn: conn} do
    conn = get(conn, "/api/v2/data-sets/@head")
    result = json_response(conn, 200)
    assert is_list(result["data"])
  end

  test "GET /api/v2/data-sets/@describe", %{conn: conn} do
    conn = get(conn, "/api/v2/data-sets/@describe")
    result = json_response(conn, 200)
    assert length(result["data"]) == 6
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

  test "POST api/v2/data-sets status", %{conn: conn} do
    conn = post(conn, "/api/v2/data-sets")
    assert conn.status == 405
  end

  test "PUT /api/v2/data-sets status", %{conn: conn} do
    conn = put(conn, "/api/v2/data-sets")
    assert conn.status == 405
  end

  test "PATCH /api/v2/data-sets status", %{conn: conn} do
    conn = patch(conn, "/api/v2/data-sets")
    assert conn.status == 405
  end

  test "DELETE /api/v2/data-sets status", %{conn: conn} do
    conn = delete(conn, "/api/v2/data-sets")
    assert conn.status == 405
  end

  test "TRACE /api/v2/data-sets status", %{conn: conn} do
    conn = trace(conn, "/api/v2/data-sets")
    assert conn.status == 405
  end

  test "CONNECT /api/v2/data-sets status", %{conn: conn} do
    conn = connect(conn, "/api/v2/data-sets")
    assert conn.status == 405
  end

  test "GET /api/v2/data-sets with bbox arg", %{conn: conn} do
    conn = get(conn, "/api/v2/data-sets?bbox=#{@seattle_geojson}")
    result = json_response(conn, 200)
    assert length(result["data"]) == 3
  end

  test "GET /api/v2/data-sets/@describe with bbox arg", %{conn: conn} do
    conn = get(conn, "/api/v2/data-sets/@describe?bbox=#{@chicago_geojson}")
    result = json_response(conn, 200)
    assert length(result["data"]) == 3
  end

  test "page_size param cannot exceed 5000" do
    get(build_conn(), "/api/v2/data-sets?page_size=5001")
    |> json_response(422)
  end

  test "page_size param cannot be less than 1" do
    get(build_conn(), "/api/v2/data-sets?page_size=0")
    |> json_response(422)
  end

  test "page_size param cannot be negative" do
    get(build_conn(), "/api/v2/data-sets?page_size=-1")
    |> json_response(422)
  end

  test "page_size cannot be a string" do
    get(build_conn(), "/api/v2/data-sets?page_size=string")
    |> json_response(422)
  end

  test "valid page_size param" do
    get(build_conn(), "/api/v2/data-sets?page_size=501")
    |> json_response(200)
  end

  test "valid page param" do
    get(build_conn(), "/api/v2/data-sets?page=1")
    |> json_response(200)
  end

  test "page param can't be zero" do
    get(build_conn(), "/api/v2/data-sets?page=0")
    |> json_response(422)
  end

  test "page param can't be negative" do
    get(build_conn(), "/api/v2/data-sets?page=-1")
    |> json_response(422)
  end

  test "page param can't be a word" do
    get(build_conn(), "/api/v2/data-sets?page=wrong")
    |> json_response(422)
  end
end
