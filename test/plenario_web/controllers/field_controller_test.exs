defmodule PlenarioWeb.Testing.FieldControllerTest do
  use PlenarioWeb.Testing.ConnCase

  import Plenario.Testing.DataCase

  describe "edit" do
    @tag :auth
    test "will display a form with the field information filled out", %{conn: conn, user: user} do
      data_set = create_data_set(%{user: user})
      field = create_field(%{data_set: data_set})

      resp =
        conn
        |> get(Routes.data_set_field_path(conn, :edit, data_set, field))
        |> html_response(:ok)

      resp =~ field.name
      resp =~ field.type
    end
  end

  describe "update" do
    @tag :auth
    test "will redirect to the parent data set show on success", %{conn: conn, user: user} do
      data_set = create_data_set(%{user: user})
      field = create_field(%{data_set: data_set})

      conn =
        conn
        |> put(Routes.data_set_field_path(conn, :update, data_set, field, %{"field" => %{"description" => "Some field"}}))

      redir = redirected_to(conn, 302)

      resp =
        conn
        |> recycle()
        |> get(redir)
        |> html_response(:ok)

      assert resp =~ "Field updated successfully"
    end
  end
end
