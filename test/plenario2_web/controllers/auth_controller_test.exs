defmodule Plenario2Web.AuthControllerTest do
  use Plenario2Web.ConnCase
  alias Plenario2Auth.UserActions

  describe "GET /login" do
    test "when anonymous", %{conn: conn} do
      response = conn
        |> get(auth_path(conn, :get_login))
        |> html_response(200)

      assert response =~ "Login Page"
    end

    test "when already authenticated", %{conn: conn} do
      UserActions.create("Test User", "password", "test@example.com")
      conn = post(conn, auth_path(conn, :do_login, %{"user" => %{"email_address" => "test@example.com", "plaintext_password" => "password"}}))

      conn = get(conn, auth_path(conn, :get_login))
      assert "/" = redir_path = redirected_to(conn, 302)
      conn = get(recycle(conn), redir_path)
      response = html_response(conn, 200)

      assert response =~ "Home"
    end
  end

  describe "POST /login" do
    test "with a good email/password", %{conn: conn} do
      {:ok, user} = UserActions.create("Test User", "password", "test@example.com")

      conn = post(conn, auth_path(conn, :do_login, %{"user" => %{"email_address" => "test@example.com", "plaintext_password" => "password"}}))
      assert "/" = redir_path = redirected_to(conn, 302)
      conn = get(recycle(conn), redir_path)
      response = html_response(conn, 200)

      assert response =~ "Home Page"
      assert response =~ "Hi, #{user.name}!"
      assert response =~ "Sign Out"
    end

    test "with a bad email/password", %{conn: conn} do
      conn = post(conn, auth_path(conn, :do_login, %{"user" => %{"email_address" => "test@example.com", "plaintext_password" => "this isn't the right password"}}))
      assert "/login" = redir_path = redirected_to(conn, 302)
      conn = get(recycle(conn), redir_path)
      response = html_response(conn, 200)

      assert response =~ "Incorrect email or password"
    end
  end

  test "POST /logout", %{conn: conn} do
    UserActions.create("Test User", "password", "test@example.com")
    conn = post(conn, auth_path(conn, :do_login, %{"user" => %{"email_address" => "test@example.com", "plaintext_password" => "password"}}))

    conn = post(conn, auth_path(conn, :logout))
    assert "/" = redir_path = redirected_to(conn, 302)
    conn = get(recycle(conn), redir_path)
    response = html_response(conn, 200)

    assert response =~ "Home Page"
  end

  describe "POST /register" do
    test "with good information", %{conn: conn} do
      conn = post(conn, auth_path(conn, :do_register), %{"user" => %{"name" => "Test User", "email_address" => "test@example.com", "plaintext_password" => "password", "organization" => nil, "org_role" => nil}})
      assert "/" = redir_path = redirected_to(conn, 302)
      conn = get(recycle(conn), redir_path)
      response = html_response(conn, 200)

      assert response =~ "Home Page"
      assert response =~ "Hi, Test User!"
      assert response =~ "Sign Out"
    end

    test "with an existing user's email address", %{conn: conn} do
      UserActions.create("Test User", "password", "test@example.com")

      response = conn
        |> post(auth_path(conn, :do_register), %{"user" => %{"name" => "Test User", "email_address" => "test@example.com", "plaintext_password" => "password", "organization" => nil, "org_role" => nil}})
        |> html_response(200)

      assert response =~ "Please review and fix errors below."
      assert response =~ "has already been taken"
    end

    test "with a bad email address", %{conn: conn} do
      response = conn
        |> post(auth_path(conn, :do_register), %{"user" => %{"name" => "Test User", "email_address" => "test@example", "plaintext_password" => "password", "organization" => nil, "org_role" => nil}})
        |> html_response(200)

      assert response =~ "Please review and fix errors below."
      assert response =~ "has invalid format"
    end
  end
end
