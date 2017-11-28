defmodule Plenario2Web.AuthControllerTest do
  use Plenario2Web.ConnCase
  alias Plenario2Auth.UserActions

  describe "GET /login" do
    test "when anonymous", %{conn: conn} do
      response = conn
        |> get(auth_path(conn, :login))
        |> html_response(200)

      assert response =~ "Login Page"
    end

    test "when already authenticated", %{conn: conn} do
      {:ok, user} = UserActions.create("Test User", "password", "test@example.com")
      conn = post(conn, auth_path(conn, :login, %{"user" => %{"email_address" => "test@example.com", "plaintext_password" => "password"}}))

      response = conn
        |> get(auth_path(conn, :login))
        |> html_response(200)

      assert response =~ "Login Page"
      assert response =~ "Hi, #{user.name}!"
      assert response =~ "Sign Out"
    end
  end

  describe "POST /login" do
    test "with a good email/password", %{conn: conn} do
      {:ok, user} = UserActions.create("Test User", "password", "test@example.com")

      conn = post(conn, auth_path(conn, :login, %{"user" => %{"email_address" => "test@example.com", "plaintext_password" => "password"}}))
      assert "/" = redir_path = redirected_to(conn, 302)
      conn = get(recycle(conn), redir_path)
      response = html_response(conn, 200)

      assert response =~ "Home Page"
      assert response =~ "Hi, #{user.name}!"
      assert response =~ "Sign Out"
    end

    test "with a bad email/password", %{conn: conn} do
      conn = post(conn, auth_path(conn, :login, %{"user" => %{"email_address" => "test@example.com", "plaintext_password" => "this isn't the right password"}}))
      assert "/login" = redir_path = redirected_to(conn, 302)
      conn = get(recycle(conn), redir_path)
      response = html_response(conn, 200)

      assert response =~ "Incorrect email or password"
    end
  end

  test "POST /logout", %{conn: conn} do
    UserActions.create("Test User", "password", "test@example.com")
    conn = post(conn, auth_path(conn, :login, %{"user" => %{"email_address" => "test@example.com", "plaintext_password" => "password"}}))

    conn = post(conn, auth_path(conn, :logout))
    assert "/" = redir_path = redirected_to(conn, 302)
    conn = get(recycle(conn), redir_path)
    response = html_response(conn, 200)

    assert response =~ "Home Page"
  end
end
