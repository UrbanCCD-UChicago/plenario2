defmodule PlenarioWeb.Testing.VirtualPointControllerTest do
  use PlenarioWeb.Testing.ConnCase

  import Plenario.Testing.DataCase

  describe "new" do
    @tag :auth
    test "will display a form", %{conn: conn, user: user} do
      data_set = create_data_set(%{user: user})
      field = create_field(%{data_set: data_set})

      resp =
        conn
        |> get(Routes.data_set_virtual_point_path(conn, :new, data_set))
        |> html_response(:ok)

      assert resp =~ field.name
    end
  end

  describe "create" do
    @tag :auth
    test "will redirect to the parent data set show on success", %{conn: conn, user: user} do
      data_set = create_data_set(%{user: user})
      field = create_field(%{data_set: data_set})

      conn =
        conn
        |> post(Routes.data_set_virtual_point_path(conn, :create, data_set, %{"virtual_point" => %{"data_set_id" => data_set.id, "loc_field_id" => field.id}}))

      redir_path = redirected_to(conn, 302)

      resp =
        conn
        |> recycle()
        |> get(redir_path)
        |> html_response(:ok)

      assert resp =~ "Created a new virtual point"
    end

    @tag :auth
    test "will stay on the form and show errors", %{conn: conn, user: user} do
      data_set = create_data_set(%{user: user})
      field = create_field(%{data_set: data_set})

      resp =
        conn
        |> post(Routes.data_set_virtual_point_path(conn, :create, data_set, %{"virtual_point" => %{"data_set_id" => data_set.id, "lon_field_id" => field.id}}))
        |> html_response(:bad_request)

      assert resp =~ "Please review and correct errors in the form below"
    end
  end

  describe "edit" do
    @tag :auth
    test "will display a form with the point information filled out", %{conn: conn, user: user} do
      data_set = create_data_set(%{user: user})
      field = create_field(%{data_set: data_set})
      point = create_virtual_point(%{data_set: data_set, field: field})

      resp =
        conn
        |> get(Routes.data_set_virtual_point_path(conn, :edit, data_set, point))
        |> html_response(:ok)

      assert resp =~ "value=\"#{field.id}\""
    end
  end

  describe "update" do
    @tag :auth
    test "will redirect to the parent data set show on success", %{conn: conn, user: user} do
      data_set = create_data_set(%{user: user})
      field = create_field(%{data_set: data_set})
      field2 = create_field(%{data_set: data_set}, [name: "another"])
      point = create_virtual_point(%{data_set: data_set, field: field})

      conn =
        conn
        |> put(Routes.data_set_virtual_point_path(conn, :update, data_set, point, %{"virtual_point" => %{"loc_field_id" => field2.id}}))

      redir_path = redirected_to(conn, 302)

      resp =
        conn
        |> recycle()
        |> get(redir_path)
        |> html_response(:ok)

      assert resp =~ "Updated virtual point"
    end

    @tag :auth
    test "will stay on the form and show errors", %{conn: conn, user: user} do
      data_set = create_data_set(%{user: user})
      field = create_field(%{data_set: data_set})
      point = create_virtual_point(%{data_set: data_set, field: field})

      resp =
        conn
        |> put(Routes.data_set_virtual_point_path(conn, :update, data_set, point, %{"virtual_point" => %{"loc_field_id" => nil}}))
        |> html_response(:bad_request)

      assert resp =~ "Please review and correct errors in the form below"
    end
  end
end
