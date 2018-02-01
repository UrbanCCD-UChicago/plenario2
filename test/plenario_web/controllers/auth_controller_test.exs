defmodule PlenarioWeb.AuthControllerTest do
  use PlenarioWeb.ConnCase, async: true

  describe "GET /login" do
    @tag :anon
    test "when anonymous", %{conn: conn} do
      response =
        conn
        |> get(auth_path(conn, :get_login))
        |> html_response(:ok)

      assert response =~ "Login Page"
    end

    @tag :auth
    test "when already authenticated", %{conn: conn} do
      conn = get(conn, auth_path(conn, :get_login))
      assert "/" = redir_path = redirected_to(conn, :found)
      conn = get(recycle(conn), redir_path)
      response = html_response(conn, :ok)

      assert response =~ "Home"
    end
  end

  describe "POST /login" do
    @tag :anon
    test "with a good email/password", %{conn: conn, reg_user: user} do
      conn =
        post(
          conn,
          auth_path(conn, :do_login, %{
            "user" => %{
              "email_address" => "regular@example.com",
              "plaintext_password" => "password"
            }
          })
        )

      assert "/" = redir_path = redirected_to(conn, :found)
      conn = get(recycle(conn), redir_path)
      response = html_response(conn, :ok)

      assert response =~ "Home Page"
      assert response =~ "Hi, #{user.name}!"
      assert response =~ "Sign Out"
    end

    @tag :anon
    test "with a bad email/password", %{conn: conn} do
      conn
      |> post(
        auth_path(conn, :do_login, %{
          "user" => %{
            "email_address" => "bad",
            "plaintext_password" => "bad"
          }
        })
      )
      |> html_response(:found)
    end
  end

  @tag :auth
  test "POST /logout", %{conn: conn} do
    conn = post(conn, auth_path(conn, :logout))
    assert "/" = redir_path = redirected_to(conn, :found)
    conn = get(recycle(conn), redir_path)
    response = html_response(conn, :ok)

    assert response =~ "Home Page"
  end

  @tag :anon
  test "GET /register", %{conn: conn} do
    response =
      conn
      |> get(auth_path(conn, :get_register))
      |> html_response(:ok)

    assert response =~ "Name"
    assert response =~ "Email"
    assert response =~ "Password"
  end

  describe "POST /register" do
    @tag :anon
    test "with good information", %{conn: conn} do
      conn =
        post(conn, auth_path(conn, :do_register), %{
          "user" => %{
            "name" => "Test User",
            "email_address" => "test@example.com",
            "plaintext_password" => "password",
            "organization" => nil,
            "org_role" => nil
          }
        })

      assert "/" = redir_path = redirected_to(conn, :found)
      conn = get(recycle(conn), redir_path)
      response = html_response(conn, :ok)

      assert response =~ "Home Page"
      assert response =~ "Hi, Test User!"
      assert response =~ "Sign Out"
    end

    @tag :anon
    test "with an existing user's email address", %{conn: conn} do
      response =
        conn
        |> post(auth_path(conn, :do_register), %{
          "user" => %{
            "name" => "Test User",
            "email_address" => "regular@example.com",
            "plaintext_password" => "password",
            "organization" => nil,
            "org_role" => nil
          }
        })
        |> html_response(:ok)

      assert response =~ "Please review and fix errors below."
      assert response =~ "has already been taken"
    end

    @tag :anon
    test "with a bad email address", %{conn: conn} do
      response =
        conn
        |> post(auth_path(conn, :do_register), %{
          "user" => %{
            "name" => "Test User",
            "email_address" => "test@example",
            "plaintext_password" => "password",
            "organization" => nil,
            "org_role" => nil
          }
        })
        |> html_response(:ok)

      assert response =~ "Please review and fix errors below."
      assert response =~ "has invalid format"
    end
  end
end
