defmodule Plenario2Web.AdminControllerTest do
  use Plenario2Web.ConnCase, async: true
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

  describe "GET /admin/users" do
    test "all", %{conn: conn} do
      {:ok, user} = UserActions.create("Test User", "password", "test@example.com")
      UserActions.promote_to_admin(user)
      conn = post(conn, auth_path(conn, :do_login, %{"user" => %{"email_address" => "test@example.com", "plaintext_password" => "password"}}))

      {:ok, archived} = UserActions.create("Archived User", "password", "archived@example.com")
      UserActions.archive(archived)
      {:ok, trusted} = UserActions.create("Trusted User", "password", "trusted@example.com")
      UserActions.trust(trusted)
      UserActions.create("Regular User", "password", "regular@example.com")

      response = conn
        |>get(admin_path(conn, :user_index))
        |> html_response(:ok)

      assert response =~ "Test User"
      assert response =~ "Archived User"
      assert response =~ "Trusted User"
      assert response =~ "Regular User"
    end

    test "active", %{conn: conn} do
      {:ok, user} = UserActions.create("Test User", "password", "test@example.com")
      UserActions.promote_to_admin(user)
      conn = post(conn, auth_path(conn, :do_login, %{"user" => %{"email_address" => "test@example.com", "plaintext_password" => "password"}}))

      {:ok, archived} = UserActions.create("Archived User", "password", "archived@example.com")
      UserActions.archive(archived)
      {:ok, trusted} = UserActions.create("Trusted User", "password", "trusted@example.com")
      UserActions.trust(trusted)
      UserActions.create("Regular User", "password", "regular@example.com")

      response = conn
        |>get(admin_path(conn, :user_index))
        |> html_response(:ok)

      assert response =~ "Test User"
      assert response =~ "Trusted User"
      assert response =~ "Regular User"
    end

    test "archived", %{conn: conn} do
      {:ok, user} = UserActions.create("Test User", "password", "test@example.com")
      UserActions.promote_to_admin(user)
      conn = post(conn, auth_path(conn, :do_login, %{"user" => %{"email_address" => "test@example.com", "plaintext_password" => "password"}}))

      {:ok, archived} = UserActions.create("Archived User", "password", "archived@example.com")
      UserActions.archive(archived)
      {:ok, trusted} = UserActions.create("Trusted User", "password", "trusted@example.com")
      UserActions.trust(trusted)
      UserActions.create("Regular User", "password", "regular@example.com")

      response = conn
        |>get(admin_path(conn, :user_index))
        |> html_response(:ok)

      assert response =~ "Archived User"
    end

    test "trusted", %{conn: conn} do
      {:ok, user} = UserActions.create("Test User", "password", "test@example.com")
      UserActions.promote_to_admin(user)
      conn = post(conn, auth_path(conn, :do_login, %{"user" => %{"email_address" => "test@example.com", "plaintext_password" => "password"}}))

      {:ok, archived} = UserActions.create("Archived User", "password", "archived@example.com")
      UserActions.archive(archived)
      {:ok, trusted} = UserActions.create("Trusted User", "password", "trusted@example.com")
      UserActions.trust(trusted)
      UserActions.create("Regular User", "password", "regular@example.com")

      response = conn
        |>get(admin_path(conn, :user_index))
        |> html_response(:ok)

      assert response =~ "Test User"
      assert response =~ "Trusted User"
    end

    test "admin", %{conn: conn} do
      {:ok, user} = UserActions.create("Test User", "password", "test@example.com")
      UserActions.promote_to_admin(user)
      conn = post(conn, auth_path(conn, :do_login, %{"user" => %{"email_address" => "test@example.com", "plaintext_password" => "password"}}))

      {:ok, archived} = UserActions.create("Archived User", "password", "archived@example.com")
      UserActions.archive(archived)
      {:ok, trusted} = UserActions.create("Trusted User", "password", "trusted@example.com")
      UserActions.trust(trusted)
      UserActions.create("Regular User", "password", "regular@example.com")

      response = conn
        |>get(admin_path(conn, :user_index))
        |> html_response(:ok)

      assert response =~ "Test User"
    end
  end

  test "PUT /admin/users/:id/archive", %{conn: conn} do
    {:ok, admin} = UserActions.create("admin", "password", "admin@example.com")
    UserActions.promote_to_admin(admin)
    conn = post(conn, auth_path(conn, :do_login, %{"user" => %{"email_address" => "admin@example.com", "plaintext_password" => "password"}}))

    {:ok, user} = UserActions.create("regular", "password", "regular@example.com")
    conn
    |> put(admin_path(conn, :archive_user, user.id))
    |> html_response(:found)

    user = UserActions.get_from_id(user.id)
    assert user.is_active == false
  end

  test "PUT /admin/users/:id/activate", %{conn: conn} do
    {:ok, admin} = UserActions.create("admin", "password", "admin@example.com")
    UserActions.promote_to_admin(admin)
    conn = post(conn, auth_path(conn, :do_login, %{"user" => %{"email_address" => "admin@example.com", "plaintext_password" => "password"}}))

    {:ok, user} = UserActions.create("regular", "password", "regular@example.com")
    conn
    |> put(admin_path(conn, :archive_user, user.id))
    |> html_response(:found)

    user = UserActions.get_from_id(user.id)
    assert user.is_active == false

    conn
    |> put(admin_path(conn, :activate_user, user.id))
    |> html_response(:found)

    user = UserActions.get_from_id(user.id)
    assert user.is_active
  end

  test "PUT /admin/users/:id/trust", %{conn: conn} do
    {:ok, admin} = UserActions.create("admin", "password", "admin@example.com")
    UserActions.promote_to_admin(admin)
    conn = post(conn, auth_path(conn, :do_login, %{"user" => %{"email_address" => "admin@example.com", "plaintext_password" => "password"}}))

    {:ok, user} = UserActions.create("regular", "password", "regular@example.com")
    conn
    |> put(admin_path(conn, :trust_user, user.id))
    |> html_response(:found)

    user = UserActions.get_from_id(user.id)
    assert user.is_trusted
  end

  test "PUT /admin/users/:id/untrust", %{conn: conn} do
    {:ok, admin} = UserActions.create("admin", "password", "admin@example.com")
    UserActions.promote_to_admin(admin)
    conn = post(conn, auth_path(conn, :do_login, %{"user" => %{"email_address" => "admin@example.com", "plaintext_password" => "password"}}))

    {:ok, user} = UserActions.create("regular", "password", "regular@example.com")
    conn
    |> put(admin_path(conn, :trust_user, user.id))
    |> html_response(:found)

    user = UserActions.get_from_id(user.id)
    assert user.is_trusted

    conn
    |> put(admin_path(conn, :untrust_user, user.id))
    |> html_response(:found)

    user = UserActions.get_from_id(user.id)
    assert user.is_trusted == false
  end

  test "PUT /admin/users/:id/promote-admin", %{conn: conn} do
    {:ok, admin} = UserActions.create("admin", "password", "admin@example.com")
    UserActions.promote_to_admin(admin)
    conn = post(conn, auth_path(conn, :do_login, %{"user" => %{"email_address" => "admin@example.com", "plaintext_password" => "password"}}))

    {:ok, user} = UserActions.create("regular", "password", "regular@example.com")
    conn
    |> put(admin_path(conn, :promote_to_admin, user.id))
    |> html_response(:found)

    user = UserActions.get_from_id(user.id)
    assert user.is_admin
  end

  test "PUT /admin/users/:id/strip-admin", %{conn: conn} do
    {:ok, admin} = UserActions.create("admin", "password", "admin@example.com")
    UserActions.promote_to_admin(admin)
    conn = post(conn, auth_path(conn, :do_login, %{"user" => %{"email_address" => "admin@example.com", "plaintext_password" => "password"}}))

    {:ok, user} = UserActions.create("regular", "password", "regular@example.com")
    conn
    |> put(admin_path(conn, :promote_to_admin, user.id))
    |> html_response(:found)

    user = UserActions.get_from_id(user.id)
    assert user.is_admin

    conn
    |> put(admin_path(conn, :strip_admin_privs, user.id))
    |> html_response(:found)

    user = UserActions.get_from_id(user.id)
    assert user.is_admin == false
  end
end
