defmodule Plenario2Web.MetaControllerTest do
  use Plenario2Web.ConnCase, async: true
  alias Plenario2.Actions.MetaActions
  alias Plenario2Auth.UserActions

  describe "GET /data-sets/create" do
    test "when authenticated", %{conn: conn} do
      UserActions.create("Test User", "password", "test@example.com")
      conn = post(conn, auth_path(conn, :do_login, %{"user" => %{"email_address" => "test@example.com", "plaintext_password" => "password"}}))

      response = conn
        |> get(meta_path(conn, :get_create))
        |> html_response(:ok)

      assert response =~ "Dataset name"
      assert response =~ "Source url"
    end

    test "when not authenticated", %{conn: conn} do
      response = conn
        |> get(meta_path(conn, :get_create))
        |> response(:unauthorized)

      assert response =~ "unauthorized"
    end
  end

  describe "POST /data-sets/create" do
    test "with valid data", %{conn: conn} do
      UserActions.create("Test User", "password", "test@example.com")
      conn = post(conn, auth_path(conn, :do_login, %{"user" => %{"email_address" => "test@example.com", "plaintext_password" => "password"}}))

      assert length(MetaActions.list()) == 0

      conn = post(conn, meta_path(conn, :do_create), %{"meta" => %{"name" => "Test Data", "source_url" => "https://example.com/test-data"}})
      assert "/data-sets/list" = redir_path = redirected_to(conn, :created)
      conn = get(recycle(conn), redir_path)
      response = html_response(conn, :ok)

      assert response =~ "Datasets"
      assert response =~ "Test Data"

      assert length(MetaActions.list()) == 1
    end

    test "with bad data", %{conn: conn} do
      UserActions.create("Test User", "password", "test@example.com")
      conn = post(conn, auth_path(conn, :do_login, %{"user" => %{"email_address" => "test@example.com", "plaintext_password" => "password"}}))

      response = conn
        |> post(meta_path(conn, :do_create), %{"meta" => %{"name" => "", "source_url" => ""}})
        |> html_response(:bad_request)

      assert response =~ "Please review and fix errors below"
    end

    test "when not authenticated", %{conn: conn} do
      response = conn
        |> post(meta_path(conn, :do_create), %{"user" => %{"name" => "", "source_url" => ""}})
        |> response(:unauthorized)

      assert response =~ "unauthorized"
    end
  end

  test "GET /data-sets/list", %{conn: conn} do
    {:ok, user} = UserActions.create("Test User", "password", "test@example.com")
    MetaActions.create("Test Data", user.id, "https://example.com/test-data")

    response = conn
      |> get(meta_path(conn, :list))
      |> html_response(:ok)

    assert response =~ "Datasets"
    assert response =~ "Test Data"
    assert response =~ "Test User"
  end

  describe "GET /data-sets/:slug" do
    test "with a valid slug", %{conn: conn} do
      {:ok, user} = UserActions.create("Test User", "password", "test@example.com")
      {:ok, meta} = MetaActions.create("Test Data", user.id, "https://example.com/test-data")

      response = conn
        |> get(meta_path(conn, :detail, meta.slug))
        |> html_response(:ok)

      assert response =~ meta.name
      assert response =~ user.name
    end

    test "with a bad slug", %{conn: conn} do
      response = conn
        |> get(meta_path(conn, :detail, "nope"))
        |> html_response(404)

      assert response =~ "not found"
    end
  end

  describe "GET /data-sets/:slug/update/name" do
    test "when authenticated and owner", %{conn: conn} do
      {:ok, user} = UserActions.create("Test User", "password", "test@example.com")
      {:ok, meta} = MetaActions.create("Test Data", user.id, "https://example.com/test-data")
      conn = post(conn, auth_path(conn, :do_login, %{"user" => %{"email_address" => "test@example.com", "plaintext_password" => "password"}}))

      response = conn
        |> get(meta_path(conn, :get_update_name, meta.slug))
        |> html_response(:ok)

      assert response =~ "Update Name"
    end

    test "when authenticated but not owner", %{conn: conn} do
      {:ok, user} = UserActions.create("Test User", "password", "test@example.com")
      UserActions.create("Test User 2", "password", "test2@example.com")
      {:ok, meta} = MetaActions.create("Test Data", user.id, "https://example.com/test-data")

      conn = post(conn, auth_path(conn, :do_login, %{"user" => %{"email_address" => "test2@example.com", "plaintext_password" => "password"}}))

      response = conn
        |> get(meta_path(conn, :get_update_name, meta.slug))
        |> response(:forbidden)

      assert response =~ "forbidden"
    end

    test "when anonymous user", %{conn: conn} do
      {:ok, user} = UserActions.create("Test User", "password", "test@example.com")
      {:ok, meta} = MetaActions.create("Test Data", user.id, "https://example.com/test-data")

      response = conn
        |> get(meta_path(conn, :get_update_name, meta.slug))
        |> response(:unauthorized)

      assert response =~ "unauthorized"
    end
  end

  describe "PUT /data-sets/:slug/update/name" do
    test "when authenticated and owner with good data", %{conn: conn} do
      {:ok, user} = UserActions.create("Test User", "password", "test@example.com")
      {:ok, meta} = MetaActions.create("Test Data", user.id, "https://example.com/test-data")
      conn = post(conn, auth_path(conn, :do_login, %{"user" => %{"email_address" => "test@example.com", "plaintext_password" => "password"}}))

      conn = put(conn, meta_path(conn, :do_update_name, meta.slug), %{"slug" => meta.slug, "meta" => %{"name" => "Some new name"}})
      redir_path = "/data-sets/#{meta.slug}/detail"
      assert redir_path == redirected_to(conn, :found)
      conn = get(recycle(conn), redir_path)
      response = html_response(conn, :ok)

      assert response =~ "Some new name"
    end

    test "when authenticated and owner with bad data", %{conn: conn} do
      {:ok, user} = UserActions.create("Test User", "password", "test@example.com")
      {:ok, meta} = MetaActions.create("Test Data", user.id, "https://example.com/test-data")
      conn = post(conn, auth_path(conn, :do_login, %{"user" => %{"email_address" => "test@example.com", "plaintext_password" => "password"}}))

      response = conn
        |> put(meta_path(conn, :do_update_name, meta.slug), %{"slug" => meta.slug, "meta" => %{"name" => ""}})
        |> html_response(:bad_request)

      assert response =~ "Please view and fix errors below."
    end

    test "when authenticated but not owner", %{conn: conn} do
      {:ok, user} = UserActions.create("Test User", "password", "test@example.com")
      UserActions.create("Test User 2", "password", "test2@example.com")
      {:ok, meta} = MetaActions.create("Test Data", user.id, "https://example.com/test-data")

      conn = post(conn, auth_path(conn, :do_login, %{"user" => %{"email_address" => "test2@example.com", "plaintext_password" => "password"}}))

      response = conn
        |> put(meta_path(conn, :do_update_name, meta.slug), %{"slug" => meta.slug, "meta" => %{"name" => "Some new name"}})
        |> response(:forbidden)

      assert response =~ "forbidden"
    end

    test "when anonymous user", %{conn: conn} do
      {:ok, user} = UserActions.create("Test User", "password", "test@example.com")
      {:ok, meta} = MetaActions.create("Test Data", user.id, "https://example.com/test-data")

      response = conn
        |> put(meta_path(conn, :do_update_name, meta.slug), %{"slug" => meta.slug, "meta" => %{"name" => "Some new name"}})
        |> response(:unauthorized)

      assert response =~ "unauthorized"
    end
  end

  describe "GET /data-sets/:slug/update/description" do
    test "when authenticated and owner", %{conn: conn} do
      {:ok, user} = UserActions.create("Test User", "password", "test@example.com")
      {:ok, meta} = MetaActions.create("Test Data", user.id, "https://example.com/test-data")
      conn = post(conn, auth_path(conn, :do_login, %{"user" => %{"email_address" => "test@example.com", "plaintext_password" => "password"}}))

      response = conn
        |> get(meta_path(conn, :get_update_description, meta.slug))
        |> html_response(:ok)

      assert response =~ "Update Description"
    end

    test "when authenticated but not owner", %{conn: conn} do
      {:ok, user} = UserActions.create("Test User", "password", "test@example.com")
      UserActions.create("Test User 2", "password", "test2@example.com")
      {:ok, meta} = MetaActions.create("Test Data", user.id, "https://example.com/test-data")

      conn = post(conn, auth_path(conn, :do_login, %{"user" => %{"email_address" => "test2@example.com", "plaintext_password" => "password"}}))

      response = conn
        |> get(meta_path(conn, :get_update_description, meta.slug))
        |> response(:forbidden)

      assert response =~ "forbidden"
    end

    test "when anonymous user", %{conn: conn} do
      {:ok, user} = UserActions.create("Test User", "password", "test@example.com")
      {:ok, meta} = MetaActions.create("Test Data", user.id, "https://example.com/test-data")

      response = conn
        |> get(meta_path(conn, :get_update_description, meta.slug))
        |> response(:unauthorized)

      assert response =~ "unauthorized"
    end
  end

  describe "PUT /data-sets/:slug/update/description" do
    test "when authenticated and owner with good data", %{conn: conn} do
      {:ok, user} = UserActions.create("Test User", "password", "test@example.com")
      {:ok, meta} = MetaActions.create("Test Data", user.id, "https://example.com/test-data")
      conn = post(conn, auth_path(conn, :do_login, %{"user" => %{"email_address" => "test@example.com", "plaintext_password" => "password"}}))

      conn = put(conn, meta_path(conn, :do_update_description, meta.slug), %{"slug" => meta.slug, "meta" => %{"description" => "I am a description", "attribution" => "I am attributing this"}})
      redir_path = "/data-sets/#{meta.slug}/detail"
      assert redir_path == redirected_to(conn, :found)
      conn = get(recycle(conn), redir_path)
      response = html_response(conn, :ok)

      assert response =~ "I am a description"
      assert response =~ "I am attributing this"
    end

    test "when authenticated but not owner", %{conn: conn} do
      {:ok, user} = UserActions.create("Test User", "password", "test@example.com")
      UserActions.create("Test User 2", "password", "test2@example.com")
      {:ok, meta} = MetaActions.create("Test Data", user.id, "https://example.com/test-data")

      conn = post(conn, auth_path(conn, :do_login, %{"user" => %{"email_address" => "test2@example.com", "plaintext_password" => "password"}}))

      response = conn
        |> put(meta_path(conn, :do_update_description, meta.slug), %{"slug" => meta.slug, "meta" => %{"description" => "I'm a description", "attribution" => "I'm attributing this"}})
        |> response(:forbidden)

      assert response =~ "forbidden"
    end

    test "when anonymous user", %{conn: conn} do
      {:ok, user} = UserActions.create("Test User", "password", "test@example.com")
      {:ok, meta} = MetaActions.create("Test Data", user.id, "https://example.com/test-data")

      response = conn
        |> put(meta_path(conn, :do_update_description, meta.slug), %{"slug" => meta.slug, "meta" => %{"description" => "I'm a description", "attribution" => "I'm attributing this"}})
        |> response(:unauthorized)

      assert response =~ "unauthorized"
    end
  end

  describe "GET /data-sets/:slug/update/source" do
    test "when authenticated and owner", %{conn: conn} do
      {:ok, user} = UserActions.create("Test User", "password", "test@example.com")
      {:ok, meta} = MetaActions.create("Test Data", user.id, "https://example.com/test-data")
      conn = post(conn, auth_path(conn, :do_login, %{"user" => %{"email_address" => "test@example.com", "plaintext_password" => "password"}}))

      response = conn
        |> get(meta_path(conn, :get_update_source_info, meta.slug))
        |> html_response(:ok)

      assert response =~ "Update Source Information"
    end

    test "when authenticated but not owner", %{conn: conn} do
      {:ok, user} = UserActions.create("Test User", "password", "test@example.com")
      UserActions.create("Test User 2", "password", "test2@example.com")
      {:ok, meta} = MetaActions.create("Test Data", user.id, "https://example.com/test-data")

      conn = post(conn, auth_path(conn, :do_login, %{"user" => %{"email_address" => "test2@example.com", "plaintext_password" => "password"}}))

      response = conn
        |> get(meta_path(conn, :get_update_source_info, meta.slug))
        |> response(:forbidden)

      assert response =~ "forbidden"
    end

    test "when anonymous user", %{conn: conn} do
      {:ok, user} = UserActions.create("Test User", "password", "test@example.com")
      {:ok, meta} = MetaActions.create("Test Data", user.id, "https://example.com/test-data")

      response = conn
        |> get(meta_path(conn, :get_update_source_info, meta.slug))
        |> response(:unauthorized)

      assert response =~ "unauthorized"
    end
  end

  describe "PUT /data-sets/:slug/update/source" do
    test "when authenticated and owner with good data", %{conn: conn} do
      {:ok, user} = UserActions.create("Test User", "password", "test@example.com")
      {:ok, meta} = MetaActions.create("Test Data", user.id, "https://example.com/test-data")
      conn = post(conn, auth_path(conn, :do_login, %{"user" => %{"email_address" => "test@example.com", "plaintext_password" => "password"}}))

      conn = put(conn, meta_path(conn, :do_update_source_info, meta.slug), %{"slug" => meta.slug, "meta" => %{"source_url" => "https://example.com/different-data", "source_type" => "csv"}})
      redir_path = "/data-sets/#{meta.slug}/detail"
      assert redir_path == redirected_to(conn, :found)
      conn = get(recycle(conn), redir_path)
      response = html_response(conn, :ok)

      assert response =~ "different-data"
    end

    test "when authenticated and owner with bad data", %{conn: conn} do
      {:ok, user} = UserActions.create("Test User", "password", "test@example.com")
      {:ok, meta} = MetaActions.create("Test Data", user.id, "https://example.com/test-data")
      conn = post(conn, auth_path(conn, :do_login, %{"user" => %{"email_address" => "test@example.com", "plaintext_password" => "password"}}))

      response = conn
        |> put(meta_path(conn, :do_update_source_info, meta.slug), %{"slug" => meta.slug, "meta" => %{"source_url" => "", "source_type" => "csv"}})
        |> html_response(:bad_request)

      assert response =~ "Please view and fix errors below."
    end

    test "when authenticated but not owner", %{conn: conn} do
      {:ok, user} = UserActions.create("Test User", "password", "test@example.com")
      UserActions.create("Test User 2", "password", "test2@example.com")
      {:ok, meta} = MetaActions.create("Test Data", user.id, "https://example.com/test-data")

      conn = post(conn, auth_path(conn, :do_login, %{"user" => %{"email_address" => "test2@example.com", "plaintext_password" => "password"}}))

      response = conn
        |> put(meta_path(conn, :do_update_source_info, meta.slug), %{"slug" => meta.slug, "meta" => %{"source_url" => "", "source_type" => "csv"}})
        |> response(:forbidden)

      assert response =~ "forbidden"
    end

    test "when anonymous user", %{conn: conn} do
      {:ok, user} = UserActions.create("Test User", "password", "test@example.com")
      {:ok, meta} = MetaActions.create("Test Data", user.id, "https://example.com/test-data")

      response = conn
        |> put(meta_path(conn, :do_update_source_info, meta.slug), %{"slug" => meta.slug, "meta" => %{"source_url" => "", "source_type" => "csv"}})
        |> response(:unauthorized)

      assert response =~ "unauthorized"
    end
  end

  describe "GET /data-sets/:slug/update/refresh" do
    test "when authenticated and owner", %{conn: conn} do
      {:ok, user} = UserActions.create("Test User", "password", "test@example.com")
      {:ok, meta} = MetaActions.create("Test Data", user.id, "https://example.com/test-data")
      conn = post(conn, auth_path(conn, :do_login, %{"user" => %{"email_address" => "test@example.com", "plaintext_password" => "password"}}))

      response = conn
        |> get(meta_path(conn, :get_update_refresh_info, meta.slug))
        |> html_response(:ok)

      assert response =~ "Update Refresh Information"
    end

    test "when authenticated but not owner", %{conn: conn} do
      {:ok, user} = UserActions.create("Test User", "password", "test@example.com")
      UserActions.create("Test User 2", "password", "test2@example.com")
      {:ok, meta} = MetaActions.create("Test Data", user.id, "https://example.com/test-data")

      conn = post(conn, auth_path(conn, :do_login, %{"user" => %{"email_address" => "test2@example.com", "plaintext_password" => "password"}}))

      response = conn
        |> get(meta_path(conn, :get_update_refresh_info, meta.slug))
        |> response(:forbidden)

      assert response =~ "forbidden"
    end

    test "when anonymous user", %{conn: conn} do
      {:ok, user} = UserActions.create("Test User", "password", "test@example.com")
      {:ok, meta} = MetaActions.create("Test Data", user.id, "https://example.com/test-data")

      response = conn
        |> get(meta_path(conn, :get_update_refresh_info, meta.slug))
        |> response(:unauthorized)

      assert response =~ "unauthorized"
    end
  end

  describe "PUT /data-sets/:slug/update/refresh" do
    test "when authenticated and owner with good data", %{conn: conn} do
      {:ok, user} = UserActions.create("Test User", "password", "test@example.com")
      {:ok, meta} = MetaActions.create("Test Data", user.id, "https://example.com/test-data")
      conn = post(conn, auth_path(conn, :do_login, %{"user" => %{"email_address" => "test@example.com", "plaintext_password" => "password"}}))

      conn = put(conn, meta_path(conn, :do_update_refresh_info, meta.slug), %{"slug" => meta.slug, "meta" => %{"refresh_rate" => "weeks", "refresh_interval" => "2", "refresh_starts_on" => "", "refresh_ends_on" => ""}})
      redir_path = "/data-sets/#{meta.slug}/detail"
      assert redir_path == redirected_to(conn, :found)
      conn = get(recycle(conn), redir_path)
      response = html_response(conn, :ok)

      assert response =~ "2 weeks"
    end

    test "when authenticated but not owner", %{conn: conn} do
      {:ok, user} = UserActions.create("Test User", "password", "test@example.com")
      UserActions.create("Test User 2", "password", "test2@example.com")
      {:ok, meta} = MetaActions.create("Test Data", user.id, "https://example.com/test-data")

      conn = post(conn, auth_path(conn, :do_login, %{"user" => %{"email_address" => "test2@example.com", "plaintext_password" => "password"}}))

      response = conn
        |> put(meta_path(conn, :do_update_refresh_info, meta.slug), %{"slug" => meta.slug, "meta" => %{"refresh_rate" => "weeks", "refresh_interval" => "2", "refresh_starts_on" => "", "refresh_ends_on" => ""}})
        |> response(:forbidden)

      assert response =~ "forbidden"
    end

    test "when anonymous user", %{conn: conn} do
      {:ok, user} = UserActions.create("Test User", "password", "test@example.com")
      {:ok, meta} = MetaActions.create("Test Data", user.id, "https://example.com/test-data")

      response = conn
        |> put(meta_path(conn, :do_update_refresh_info, meta.slug), %{"slug" => meta.slug, "meta" => %{"refresh_rate" => "weeks", "refresh_interval" => "2", "refresh_starts_on" => "", "refresh_ends_on" => ""}})
        |> response(:unauthorized)

      assert response =~ "unauthorized"
    end
  end

  test ":submit_for_approval", %{conn: conn} do
    {:ok, user} = UserActions.create("test user", "password", "test@example.com")
    {:ok, meta} = MetaActions.create("test data", user.id, "https://example.com/")

    conn = post(conn, auth_path(conn, :do_login, %{"user" => %{"email_address" => "test@example.com", "plaintext_password" => "password"}}))

    meta = MetaActions.get_from_id(meta.id)
    conn
    |> post(meta_path(conn, :submit_for_approval, meta.slug))
    |> html_response(:found)
  end
end
