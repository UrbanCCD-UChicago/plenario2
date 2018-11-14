defmodule PlenarioWeb.Testing.SessionsTest do
  use PlenarioWeb.Testing.ConnCase

  import Plenario.Testing.DataCase

  describe "log in" do
    test "successful login will assign :current_user to user", %{conn: conn} do
      user = create_user()

      conn =
        conn
        |> post(Routes.session_path(conn, :login, %{"user" => %{"email" => user.email, "password" => "password"}}))

      redir_path = redirected_to(conn, 302)

      conn =
        conn
        |> recycle()
        |> get(redir_path)

      assert html_response(conn, :ok)
      assert conn.assigns[:current_user].id == user.id
    end

    test "bad credentials", %{conn: conn} do
      conn
      |> post(Routes.session_path(conn, :login, %{"user" => %{"email" => "nope", "password" => "nope"}}))
      |> html_response(:bad_request)
    end
  end

  describe "logout" do
    @tag :auth
    test "will assign :current_user to nil", %{conn: conn} do
      conn =
        conn
        |> post(Routes.session_path(conn, :logout))
        |> recycle()

      assert is_nil conn.assigns[:current_user]
    end
  end

  describe "register" do
    test "successful registration will assign :current_user to user", %{conn: conn} do
      username = "New User"

      conn =
        conn
        |> post(Routes.session_path(conn, :register, %{"user" => %{"username" => username, "email" => "new@example.com", "password" => "password"}}))

      redir_path = redirected_to(conn, 302)

      conn =
        conn
        |> recycle()
        |> get(redir_path)

      assert html_response(conn, :ok)
      assert conn.assigns[:current_user].username == username
    end

    test "with a taken username", %{conn: conn} do
      user = create_user()

      conn
      |> post(Routes.session_path(conn, :register, %{"user" => %{"username" => user.username, "email" => "new@example.com", "password" => "password"}}))
      |> html_response(:bad_request)
    end

    test "with a taken email address", %{conn: conn} do
      user = create_user()

      conn
      |> post(Routes.session_path(conn, :register, %{"user" => %{"username" => "New User", "email" => user.email, "password" => "password"}}))
      |> html_response(:bad_request)
    end
  end
end
