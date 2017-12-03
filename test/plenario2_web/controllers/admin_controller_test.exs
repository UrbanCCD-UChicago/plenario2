defmodule Plenario2Web.AdminControllerTest do
  use Plenario2Web.ConnCase
  alias Plenario2Auth.UserActions

  describe "GET /admin" do
    test "as an authenticated user with admin permissions", %{conn: conn} do
      {:ok, user} = UserActions.create("Test User", "password", "test@example.com")
      UserActions.promote_to_admin(user)
      conn = post(conn, auth_path(conn, :do_login, %{"user" => %{"email_address" => "test@example.com", "plaintext_password" => "password"}}))

      response = conn
        |> get(admin_path(conn, :index))
        |> html_response(:ok)

      assert response =~ "Admin"
    end

    test "as an authenticated user without admin permissions", %{conn: conn} do
      UserActions.create("Test User", "password", "test@example.com")

      conn = post(conn, auth_path(conn, :do_login, %{"user" => %{"email_address" => "test@example.com", "plaintext_password" => "password"}}))

      response = conn
        |> get(admin_path(conn, :index))
        |> response(:forbidden)

      assert response =~ "forbidden"
    end

    test "as an anonymous user", %{conn: conn} do
      response = conn
        |> get(admin_path(conn, :index))
        |> response(:unauthorized)

      assert response =~ "unauthorized"
    end
  end
end
