defmodule PlenarioWeb.VirtualPointFieldControllerTest do
  use PlenarioWeb.ConnCase, async: true

  alias Plenario.Actions.{MetaActions, DataSetFieldActions, VirtualPointFieldActions}

  @meta_name "Test Data Set"
  @meta_source_url "https://example.com/"

  setup context do
    {:ok, meta} = MetaActions.create(@meta_name, context.reg_user.id, @meta_source_url)

    DataSetFieldActions.create(meta.id, "event id", "text")
    DataSetFieldActions.create(meta.id, "location", "text")
    DataSetFieldActions.create(meta.id, "long", "float")
    DataSetFieldActions.create(meta.id, "lat", "float")
    DataSetFieldActions.create(meta.id, "yr", "integer")
    DataSetFieldActions.create(meta.id, "mo", "integer")
    DataSetFieldActions.create(meta.id, "day", "integer")

    %{meta: meta}
  end

  @tag :auth
  test ":get_create_loc", %{conn: conn, meta: meta} do
    response =
      conn
      |> get(virtual_point_field_path(conn, :get_create_loc, meta.slug))
      |> html_response(:ok)

    assert response =~ "event_id"
    assert response =~ "location"
  end

  @tag :auth
  test ":do_create_loc", %{conn: conn, meta: meta} do
    conn
    |> post(virtual_point_field_path(conn, :do_create_loc, meta.slug), %{
      "virtual_point_field" => %{
        "meta_id" => meta.id,
        "location_field" => "location"
      }
    })
    |> html_response(:found)

    assert Enum.count(VirtualPointFieldActions.list_for_meta(meta)) == 1
  end

  @tag :auth
  test ":get_create_longlat", %{conn: conn, meta: meta} do
    response =
      conn
      |> get(virtual_point_field_path(conn, :get_create_longlat, meta.slug))
      |> html_response(:ok)

    assert response =~ "long"
    assert response =~ "lat"
  end

  @tag :auth
  test ":do_create_longlat", %{conn: conn, meta: meta} do
    conn
    |> post(virtual_point_field_path(conn, :do_create_longlat, meta.slug), %{
      "virtual_point_field" => %{
        "meta_id" => meta.id,
        "longitude_field" => "long",
        "latitude_field" => "lat"
      }
    })
    |> html_response(:found)

    assert Enum.count(VirtualPointFieldActions.list_for_meta(meta)) == 1
  end
end
