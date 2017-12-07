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

  test ":get_update_email", %{conn: conn} do
    UserActions.create("test", "password", "test@example.com")
    conn = post(conn, auth_path(conn, :do_login, %{"user" => %{"email_address" => "test@example.com", "plaintext_password" => "password"}}))

    res = conn
      |> get(user_path(conn, :get_update_email))
      |> html_response(:ok)

    assert res =~ "Update Your Email Address"
  end

  describe ":do_update_email" do
    test "with a good email address", %{conn: conn} do
      UserActions.create("test", "password", "test@example.com")
      conn = post(conn, auth_path(conn, :do_login, %{"user" => %{"email_address" => "test@example.com", "plaintext_password" => "password"}}))

      conn
      |> put(user_path(conn, :do_update_email, %{"user" => %{"email_address" => "test2@example.com"}}))
      |> html_response(:found)

      user = UserActions.get_from_email("test2@example.com")
      assert user.name == "test"

      post(conn, auth_path(conn, :do_login, %{"user" => %{"email_address" => "test2@example.com", "plaintext_password" => "password"}}))
    end

    test "with a bad email address", %{conn: conn} do
      UserActions.create("test", "password", "test@example.com")
      conn = post(conn, auth_path(conn, :do_login, %{"user" => %{"email_address" => "test@example.com", "plaintext_password" => "password"}}))

      conn
      |> put(user_path(conn, :do_update_email, %{"user" => %{"email_address" => "i'm not giving my email to a machine"}}))
      |> html_response(:bad_request)
    end
  end

  test ":get_update_org_info", %{conn: conn} do
    UserActions.create("test", "password", "test@example.com")
    conn = post(conn, auth_path(conn, :do_login, %{"user" => %{"email_address" => "test@example.com", "plaintext_password" => "password"}}))

    res = conn
      |> get(user_path(conn, :get_update_org_info))
      |> html_response(:ok)

    assert res =~ "Update Your Organization Info"
  end

  test ":do_update_org_info", %{conn: conn} do
    UserActions.create("test", "password", "test@example.com")
    conn = post(conn, auth_path(conn, :do_login, %{"user" => %{"email_address" => "test@example.com", "plaintext_password" => "password"}}))

    conn
    |> put(user_path(conn, :do_update_org_info, %{"user" => %{"organization" => "University of Chicago", "org_role" => "Internet Janitor"}}))
    |> html_response(:found)

    user = UserActions.get_from_email("test@example.com")
    assert user.organization == "University of Chicago"
    assert user.org_role == "Internet Janitor"
  end
end
