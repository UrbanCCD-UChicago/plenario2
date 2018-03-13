defmodule PlenarioWeb.Web.Testing.VirtualPointControllerTest do
  use PlenarioWeb.Testing.ConnCase 

  alias Plenario.Actions.{
    MetaActions,
    DataSetFieldActions,
    VirtualPointFieldActions
  }

  setup %{reg_user: user} do
    {:ok, meta} = MetaActions.create("name", user, "https://example.com/", "csv")
    {:ok, field} = DataSetFieldActions.create(meta, "name", "text")
    {:ok, field2} = DataSetFieldActions.create(meta, "name2", "text")
    {:ok, vpf} = VirtualPointFieldActions.create(meta, field.id)

    {:ok, [meta: meta, field: field, field2: field2, vpf: vpf]}
  end

  @tag :auth
  test "new", %{conn: conn, meta: meta} do
    conn
    |> get(virtual_point_path(conn, :new, meta.id))
    |> html_response(:ok)
  end

  describe "create" do
    @tag :auth
    test "with good inputs", %{conn: conn, meta: meta, field2: field} do
      params = %{
        "virtual_point_field" => %{
          "meta_id" => meta.id,
          "loc_field_id" => field.id,
          "lat_field_id" => "",
          "lon_field_id" => ""
        }
      }

      conn
      |> post(virtual_point_path(conn, :create, meta.id, params))
      |> html_response(:found)
    end
  end

  @tag :auth
  test "edit", %{conn: conn, meta: meta, vpf: vpf} do
    conn
    |> get(virtual_point_path(conn, :edit, meta.id, vpf.id))
    |> html_response(:ok)
  end

  describe "update" do
    @tag :auth
    test "with good inputs", %{conn: conn, meta: meta, vpf: vpf, field2: field} do
      params = %{
        "virtual_point_field" => %{
          "meta_id" => meta.id,
          "loc_field_id" => field.id
        }
      }

      conn
      |> put(virtual_point_path(conn, :update, meta.id, vpf.id, params))
      |> html_response(:found)
    end
  end

  @tag :auth
  test "delete", %{conn: conn, meta: meta, vpf: vpf} do
    conn
    |> delete(virtual_point_path(conn, :delete, meta.id, vpf.id))
    |> html_response(:found)

    refute VirtualPointFieldActions.get(vpf.id)
  end
end
