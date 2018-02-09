defmodule PlenarioWeb.Web.Testing.DataSetControllerTest do
  use PlenarioWeb.Testing.ConnCase, async: true

  alias Plenario.Actions.{MetaActions, DataSetFieldActions}

  setup %{reg_user: user} do
    {:ok, meta} = MetaActions.create("name", user, "https://example.com/", "csv")
    {:ok, field} = DataSetFieldActions.create(meta, "name", "text")

    {:ok, [meta: meta, field: field]}
  end

  @tag :auth
  test "edit", %{conn: conn, meta: meta, field: field} do
    conn
    |> get(data_set_field_path(conn, :edit, meta.id, field.id))
    |> html_response(:ok)
  end

  describe "update" do
    @tag :auth
    test "with good inputs", %{conn: conn, meta: meta, field: field} do
      params = %{
        "data_set_field" => %{
          "type" => "jsonb"
        }
      }

      conn
      |> put(data_set_field_path(conn, :update, meta.id, field.id, params))
      |> html_response(:found)

      field = DataSetFieldActions.get(field.id)
      assert field.type == "jsonb"
    end

    @tag :auth
    test "with bad inputs", %{conn: conn, meta: meta, field: field} do
      params = %{
        "data_set_field" => %{
          "type" => "i have no idea"
        }
      }

      conn
      |> put(data_set_field_path(conn, :update, meta.id, field.id, params))
      |> html_response(:bad_request)
    end
  end

  @tag :auth
  test "delete", %{conn: conn, meta: meta, field: field} do
    conn
    |> delete(data_set_field_path(conn, :delete, meta.id, field.id))
    |> html_response(:found)

    refute DataSetFieldActions.get(field.id)
  end
end
