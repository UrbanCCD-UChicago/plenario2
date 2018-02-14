defmodule PlenarioWeb.Admin.Testing.AdminPageControllerTest do
  use PlenarioWeb.Testing.ConnCase, async: true

  @tag :admin
  test "index", %{conn: conn} do
    conn
    |> get(admin_page_path(conn, :index))
    |> html_response(:ok)
  end
end
