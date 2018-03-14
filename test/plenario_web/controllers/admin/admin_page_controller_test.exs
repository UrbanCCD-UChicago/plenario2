defmodule PlenarioWeb.Admin.Testing.AdminPageControllerTest do
  use PlenarioWeb.Testing.ConnCase 

  @tag :admin
  test "index", %{conn: conn} do
    conn
    |> get(admin_page_path(conn, :index))
    |> html_response(:ok)
  end
end
