defmodule PlenarioAuth.Testing.AdminPlugTest do
  use PlenarioWeb.Testing.ConnCase, async: true

  @tag :anon
  test "anonymous users cannot access admin routes", %{conn: conn} do
    conn
    |> get(user_path(conn, :index))
    |> html_response(:found)
  end

  @tag :auth
  test "authenticated regular users cannot access admin routes", %{conn: conn} do
    conn
    |> get(user_path(conn, :index))
    |> html_response(:forbidden)
  end

  @tag :admin
  test "authenticated admin status users can access admin routes", %{conn: conn} do
    conn
    |> get(user_path(conn, :index))
    |> html_response(:ok)
  end
end
