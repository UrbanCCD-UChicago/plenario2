defmodule PlenarioWeb.Web.Testing.VirtualDateControllerTest do
  use PlenarioWeb.Testing.ConnCase 

  alias Plenario.Actions.{
    MetaActions,
    DataSetFieldActions,
    VirtualDateFieldActions
  }

  setup %{reg_user: user} do
    {:ok, meta} = MetaActions.create("name", user, "https://example.com/", "csv")
    {:ok, field} = DataSetFieldActions.create(meta, "name", "text")
    {:ok, field2} = DataSetFieldActions.create(meta, "name2", "text")
    {:ok, vdf} = VirtualDateFieldActions.create(meta, field.id)

    {:ok, [meta: meta, field: field, field2: field2, vdf: vdf]}
  end

  @tag :auth
  test "new", %{conn: conn, meta: meta} do
    conn
    |> get(virtual_date_path(conn, :new, meta.id))
    |> html_response(:ok)
  end

  describe "create" do
    @tag :auth
    test "with good inputs", %{conn: conn, meta: meta, field2: field} do
      params = %{
        "virtual_date_field" => %{
          "meta_id" => meta.id,
          "year_field_id" => field.id
        }
      }

      conn
      |> post(virtual_date_path(conn, :create, meta.id, params))
      |> html_response(:found)
    end
  end

  @tag :auth
  test "edit", %{conn: conn, meta: meta, vdf: vdf} do
    conn
    |> get(virtual_date_path(conn, :edit, meta.id, vdf.id))
    |> html_response(:ok)
  end

  describe "update" do
    @tag :auth
    test "with good inputs", %{conn: conn, meta: meta, vdf: vdf, field2: field} do
      params = %{
        "virtual_date_field" => %{
          "meta_id" => meta.id,
          "year_field_id" => field.id
        }
      }

      conn
      |> put(virtual_date_path(conn, :update, meta.id, vdf.id, params))
      |> html_response(:found)

      vdf = VirtualDateFieldActions.get(vdf.id)
      assert vdf.year_field_id == field.id
    end
  end

  @tag :auth
  test "delete", %{conn: conn, meta: meta, vdf: vdf} do
    conn
    |> delete(virtual_date_path(conn, :delete, meta.id, vdf.id))
    |> html_response(:found)

    refute VirtualDateFieldActions.get(vdf.id)
  end
end
