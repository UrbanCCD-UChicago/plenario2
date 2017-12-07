defmodule Plenario2Web.UserControllerTest do
  use Plenario2Web.ConnCase, async: true
  alias Plenario2Auth.UserActions

  describe ":index" do
    test "as anonymous", %{conn: conn} do
      conn
      |> get(user_path(conn, :index))
      |> response(:unauthorized)
    end

    test "as a logged in user", %{conn: conn} do
      UserActions.create("test", "password", "test@example.com")
      conn = post(conn, auth_path(conn, :do_login, %{"user" => %{"email_address" => "test@example.com", "plaintext_password" => "password"}}))

      conn
      |> get(user_path(conn, :index))
      |> html_response(:ok)
    end
  end

  test ":get_update_name", %{conn: conn} do
    UserActions.create("test", "password", "test@example.com")
    conn = post(conn, auth_path(conn, :do_login, %{"user" => %{"email_address" => "test@example.com", "plaintext_password" => "password"}}))

    res = conn
      |> get(user_path(conn, :get_update_name))
      |> html_response(:ok)

    assert res =~ "Update Your Name"
  end

  test ":do_update_name", %{conn: conn} do
    UserActions.create("test", "password", "test@example.com")
    conn = post(conn, auth_path(conn, :do_login, %{"user" => %{"email_address" => "test@example.com", "plaintext_password" => "password"}}))

    conn
    |> put(user_path(conn, :do_update_name, %{"user" => %{"name" => "My New Name"}}))
    |> html_response(:found)

    user = UserActions.get_from_email("test@example.com")
    assert user.name == "My New Name"
  end
end
