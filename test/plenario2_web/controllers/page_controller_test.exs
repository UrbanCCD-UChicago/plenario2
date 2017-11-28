defmodule Plenario2Web.PageControllerTest do
  use Plenario2Web.ConnCase
  alias Plenario2Auth.UserActions

  test "GET /", %{conn: conn} do
    response =
      conn
      |> get(page_path(conn, :index))
      |> html_response(200)

    assert response =~ "No one is logged in"
  end

  describe "POST /" do
    test "with good email and password", %{conn: conn} do
      {:ok, user} = UserActions.create("Test User", "password", "test@example.com")

      conn = post(conn, page_path(conn, :login, %{"user" => %{"email_address" => "test@example.com", "plaintext_password" => "password"}}))
      assert "/" = redir_path = redirected_to(conn, 302)
      conn = get(recycle(conn), redir_path)
      response = html_response(conn, 200)

      assert response =~ "Hello #{user.name}!"
    end

    test "with a bad email and/or password", %{conn: conn} do
      conn = post(conn, page_path(conn, :login, %{"user" => %{"email_address" => "test@example.com", "plaintext_password" => "this isn't the right password"}}))
      assert "/" = redir_path = redirected_to(conn, 302)
      conn = get(recycle(conn), redir_path)
      response = html_response(conn, 200)

      assert response =~ "Incorrect email or password"
    end
  end

  test "POST /logout", %{conn: conn} do
    UserActions.create("Test User", "password", "test@example.com")
    conn = post(conn, page_path(conn, :login, %{"user" => %{"email_address" => "test@example.com", "plaintext_password" => "password"}}))

    conn = post(conn, page_path(conn, :logout))
    assert "/" = redir_path = redirected_to(conn, 302)
    conn = get(recycle(conn), redir_path)
    response = html_response(conn, 200)

    assert response =~ "No one is logged in"
  end

  describe "GET /secret" do
    test "when authenticated", %{conn: conn} do
      UserActions.create("Test User", "password", "test@example.com")
      conn = post(conn, page_path(conn, :login, %{"user" => %{"email_address" => "test@example.com", "plaintext_password" => "password"}}))

      response =
        conn
        |> get(page_path(conn, :secret))
        |> html_response(200)

      assert response =~ "Secret Page"
    end

    test "when anonymous", %{conn: conn} do
      response =
        conn
        |> get(page_path(conn, :secret))

      assert response.status == 401
    end
  end
end
