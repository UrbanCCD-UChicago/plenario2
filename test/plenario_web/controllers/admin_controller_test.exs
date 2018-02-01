defmodule PlenarioWeb.AdminControllerTest do
  use PlenarioWeb.ConnCase, async: true

  alias PlenarioAuth.UserActions

  alias Plenario.Actions.MetaActions

  describe "GET /admin" do
    @tag :admin
    test "as an authenticated user with admin permissions", %{conn: conn} do
      response =
        conn
        |> get(admin_path(conn, :index))
        |> html_response(:ok)

      assert response =~ "Admin"
    end

    @tag :auth
    test "as an authenticated user without admin permissions", %{conn: conn} do
      response =
        conn
        |> get(admin_path(conn, :index))
        |> response(:forbidden)

      assert response =~ "forbidden"
    end

    @tag :anon
    test "as an anonymous user", %{conn: conn} do
      response =
        conn
        |> get(admin_path(conn, :index))
        |> response(:unauthorized)

      assert response =~ "unauthorized"
    end
  end

  describe "GET /admin/users" do
    @tag :admin
    test "all", %{conn: conn} do
      {:ok, archived} = UserActions.create("Archived User", "password", "archived@example.com")
      UserActions.archive(archived)

      {:ok, trusted} = UserActions.create("Trusted User", "password", "trusted@example.com")
      UserActions.trust(trusted)

      response =
        conn
        |> get(admin_path(conn, :user_index))
        |> html_response(:ok)

      assert response =~ "Admin User"
      assert response =~ "Regular User"
      assert response =~ "Archived User"
      assert response =~ "Trusted User"
    end

    @tag :admin
    test "active", %{conn: conn} do
      {:ok, archived} = UserActions.create("Archived User", "password", "archived@example.com")
      UserActions.archive(archived)

      {:ok, trusted} = UserActions.create("Trusted User", "password", "trusted@example.com")
      UserActions.trust(trusted)

      response =
        conn
        |> get(admin_path(conn, :user_index))
        |> html_response(:ok)

      assert response =~ "Admin User"
      assert response =~ "Regular User"
      assert response =~ "Trusted User"
    end

    @tag :admin
    test "archived", %{conn: conn} do
      {:ok, archived} = UserActions.create("Archived User", "password", "archived@example.com")
      UserActions.archive(archived)

      {:ok, trusted} = UserActions.create("Trusted User", "password", "trusted@example.com")
      UserActions.trust(trusted)

      response =
        conn
        |> get(admin_path(conn, :user_index))
        |> html_response(:ok)

      assert response =~ "Archived User"
    end

    @tag :admin
    test "trusted", %{conn: conn} do
      {:ok, archived} = UserActions.create("Archived User", "password", "archived@example.com")
      UserActions.archive(archived)

      {:ok, trusted} = UserActions.create("Trusted User", "password", "trusted@example.com")
      UserActions.trust(trusted)

      response =
        conn
        |> get(admin_path(conn, :user_index))
        |> html_response(:ok)

      assert response =~ "Admin User"
      assert response =~ "Trusted User"
    end

    @tag :admin
    test "admin", %{conn: conn} do
      {:ok, archived} = UserActions.create("Archived User", "password", "archived@example.com")
      UserActions.archive(archived)

      {:ok, trusted} = UserActions.create("Trusted User", "password", "trusted@example.com")
      UserActions.trust(trusted)

      response =
        conn
        |> get(admin_path(conn, :user_index))
        |> html_response(:ok)

      assert response =~ "Admin User"
    end
  end

  @tag :admin
  test "PUT /admin/users/:id/archive", %{conn: conn, reg_user: user} do
    conn
    |> put(admin_path(conn, :archive_user, user.id))
    |> html_response(:found)

    user = UserActions.get_from_id(user.id)
    assert user.is_active == false
  end

  @tag :admin
  test "PUT /admin/users/:id/activate", %{conn: conn, reg_user: user} do
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

  @tag :admin
  test "PUT /admin/users/:id/trust", %{conn: conn, reg_user: user} do
    conn
    |> put(admin_path(conn, :trust_user, user.id))
    |> html_response(:found)

    user = UserActions.get_from_id(user.id)
    assert user.is_trusted
  end

  @tag :admin
  test "PUT /admin/users/:id/untrust", %{conn: conn, reg_user: user} do
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

  @tag :admin
  test "PUT /admin/users/:id/promote-admin", %{conn: conn, reg_user: user} do
    conn
    |> put(admin_path(conn, :promote_to_admin, user.id))
    |> html_response(:found)

    user = UserActions.get_from_id(user.id)
    assert user.is_admin
  end

  @tag :admin
  test "PUT /admin/users/:id/strip-admin", %{conn: conn, reg_user: user} do
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

  @tag :admin
  test :meta_index, %{conn: conn, admin_user: admin} do
    {:ok, meta} = MetaActions.create("test", admin.id, "https://example.com/")

    meta = MetaActions.get(meta.id, with_user: true)
    MetaActions.submit_for_approval(meta)

    response =
      conn
      |> get(admin_path(conn, :meta_index))
      |> html_response(:ok)

    assert response =~ "Metas"
    assert response =~ "Ready"
    assert response =~ "Erred"
    assert response =~ "Need Approval"
    assert response =~ "New"
  end

  @tag :admin
  test :get_meta_approval_review, %{conn: conn, admin_user: admin} do
    {:ok, meta} = MetaActions.create("test", admin.id, "https://example.com/")

    meta = MetaActions.get(meta.id, with_user: true)
    MetaActions.submit_for_approval(meta)

    response =
      conn
      |> get(admin_path(conn, :get_meta_approval_review, meta.id))
      |> html_response(:ok)

    assert response =~ meta.name
  end

  @tag :admin
  test :approve_meta, %{conn: conn, admin_user: admin} do
    {:ok, meta} = MetaActions.create("test", admin.id, "https://example.com/")

    meta = MetaActions.get(meta.id, with_user: true)
    MetaActions.submit_for_approval(meta)

    post(conn, admin_path(conn, :approve_meta, meta.id))

    meta = MetaActions.get(meta.id, with_user: true)
    assert meta.state == "ready"
  end

  @tag :admin
  test :disapprove_meta, %{conn: conn, admin_user: admin} do
    {:ok, meta} = MetaActions.create("test", admin.id, "https://example.com/")

    meta = MetaActions.get(meta.id, with_user: true)
    MetaActions.submit_for_approval(meta)

    post(conn, admin_path(conn, :disapprove_meta, meta.id, message: "test"))

    meta = MetaActions.get(meta.id, with_user: true)
    assert meta.state == "new"
  end
end
