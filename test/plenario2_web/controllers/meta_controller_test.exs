defmodule Plenario2Web.MetaControllerTest do
  use Plenario2Web.ConnCase, async: true

  alias Plenario2.Actions.MetaActions

  describe "GET /data-sets/create" do

    @tag :auth
    test "when authenticated", %{conn: conn} do
      response = conn
        |> get(meta_path(conn, :get_create))
        |> html_response(:ok)

      assert response =~ "Dataset name"
      assert response =~ "Source url"
    end

    @tag :anon
    test "when not authenticated", %{conn: conn} do
      response = conn
        |> get(meta_path(conn, :get_create))
        |> response(:unauthorized)

      assert response =~ "unauthorized"
    end
  end

  describe "POST /data-sets/create" do

    @tag :auth
    test "with valid data", %{conn: conn} do
      assert length(MetaActions.list()) == 0

      conn = post(conn, meta_path(conn, :do_create), %{"meta" => %{"name" => "Test Data", "source_url" => "https://example.com/test-data"}})
      assert "/data-sets/list" = redir_path = redirected_to(conn, :found)
      conn = get(recycle(conn), redir_path)
      response = html_response(conn, :ok)

      assert response =~ "Datasets"
      assert response =~ "Test Data"

      assert length(MetaActions.list()) == 1
    end

    @tag :auth
    test "with bad data", %{conn: conn} do
      response = conn
        |> post(meta_path(conn, :do_create), %{"meta" => %{"name" => "", "source_url" => ""}})
        |> html_response(:bad_request)

      assert response =~ "Please review and fix errors below"
    end

    @tag :anon
    test "when not authenticated", %{conn: conn} do
      response = conn
        |> post(meta_path(conn, :do_create), %{"user" => %{"name" => "", "source_url" => ""}})
        |> response(:unauthorized)

      assert response =~ "unauthorized"
    end
  end

  @tag :anon
  test "GET /data-sets/list", %{conn: conn, reg_user: user} do
    MetaActions.create("Test Data", user.id, "https://example.com/test-data")

    response = conn
      |> get(meta_path(conn, :list))
      |> html_response(:ok)

    assert response =~ "Datasets"
    assert response =~ "Test Data"
    assert response =~ "Regular User"
  end

  describe "GET /data-sets/:slug" do

    @tag :anon
    test "with a valid slug", %{conn: conn, reg_user: user} do
      {:ok, meta} = MetaActions.create("Test Data", user.id, "https://example.com/test-data")

      response = conn
        |> get(meta_path(conn, :detail, meta.slug))
        |> html_response(:ok)

      assert response =~ meta.name
      assert response =~ user.name
    end

    @tag :anon
    test "with a bad slug", %{conn: conn} do
      response = conn
        |> get(meta_path(conn, :detail, "nope"))
        |> html_response(404)

      assert response =~ "not found"
    end
  end

  describe "GET /data-sets/:slug/update/name" do

    @tag :auth
    test "when authenticated and owner", %{conn: conn, reg_user: user} do
      {:ok, meta} = MetaActions.create("Test Data", user.id, "https://example.com/test-data")

      response = conn
        |> get(meta_path(conn, :get_update_name, meta.slug))
        |> html_response(:ok)

      assert response =~ "Update Name"
    end

    @tag :auth
    test "when authenticated but not owner", %{conn: conn, admin_user: user} do
      {:ok, meta} = MetaActions.create("Test Data", user.id, "https://example.com/test-data")

      response = conn
        |> get(meta_path(conn, :get_update_name, meta.slug))
        |> response(:forbidden)

      assert response =~ "forbidden"
    end

    @tag :anon
    test "when anonymous user", %{conn: conn, reg_user: user} do
      {:ok, meta} = MetaActions.create("Test Data", user.id, "https://example.com/test-data")

      response = conn
        |> get(meta_path(conn, :get_update_name, meta.slug))
        |> response(:unauthorized)

      assert response =~ "unauthorized"
    end
  end

  describe "PUT /data-sets/:slug/update/name" do

    @tag :auth
    test "when authenticated and owner with good data", %{conn: conn, reg_user: user} do
      {:ok, meta} = MetaActions.create("Test Data", user.id, "https://example.com/test-data")

      conn = put(conn, meta_path(conn, :do_update_name, meta.slug), %{"slug" => meta.slug, "meta" => %{"name" => "Some new name"}})
      redir_path = "/data-sets/#{meta.slug}/detail"
      assert redir_path == redirected_to(conn, :found)
      conn = get(recycle(conn), redir_path)
      response = html_response(conn, :ok)

      assert response =~ "Some new name"
    end

    @tag :auth
    test "when authenticated and owner with bad data", %{conn: conn, reg_user: user} do
      {:ok, meta} = MetaActions.create("Test Data", user.id, "https://example.com/test-data")

      response = conn
        |> put(meta_path(conn, :do_update_name, meta.slug), %{"slug" => meta.slug, "meta" => %{"name" => ""}})
        |> html_response(:bad_request)

      assert response =~ "Please view and fix errors below."
    end

    @tag :auth
    test "when authenticated but not owner", %{conn: conn, admin_user: user} do
      {:ok, meta} = MetaActions.create("Test Data", user.id, "https://example.com/test-data")

      response = conn
        |> put(meta_path(conn, :do_update_name, meta.slug), %{"slug" => meta.slug, "meta" => %{"name" => "Some new name"}})
        |> response(:forbidden)

      assert response =~ "forbidden"
    end

    @tag :anon
    test "when anonymous user", %{conn: conn, reg_user: user} do
      {:ok, meta} = MetaActions.create("Test Data", user.id, "https://example.com/test-data")

      response = conn
        |> put(meta_path(conn, :do_update_name, meta.slug), %{"slug" => meta.slug, "meta" => %{"name" => "Some new name"}})
        |> response(:unauthorized)

      assert response =~ "unauthorized"
    end
  end

  describe "GET /data-sets/:slug/update/description" do

    @tag :auth
    test "when authenticated and owner", %{conn: conn, reg_user: user} do
      {:ok, meta} = MetaActions.create("Test Data", user.id, "https://example.com/test-data")

      response = conn
        |> get(meta_path(conn, :get_update_description, meta.slug))
        |> html_response(:ok)

      assert response =~ "Update Description"
    end

    @tag :auth
    test "when authenticated but not owner", %{conn: conn, admin_user: user} do
      {:ok, meta} = MetaActions.create("Test Data", user.id, "https://example.com/test-data")

      response = conn
        |> get(meta_path(conn, :get_update_description, meta.slug))
        |> response(:forbidden)

      assert response =~ "forbidden"
    end

    @tag :anon
    test "when anonymous user", %{conn: conn, reg_user: user} do
      {:ok, meta} = MetaActions.create("Test Data", user.id, "https://example.com/test-data")

      response = conn
        |> get(meta_path(conn, :get_update_description, meta.slug))
        |> response(:unauthorized)

      assert response =~ "unauthorized"
    end
  end

  describe "PUT /data-sets/:slug/update/description" do

    @tag :auth
    test "when authenticated and owner with good data", %{conn: conn, reg_user: user} do
      {:ok, meta} = MetaActions.create("Test Data", user.id, "https://example.com/test-data")

      conn = put(conn, meta_path(conn, :do_update_description, meta.slug), %{"slug" => meta.slug, "meta" => %{"description" => "I am a description", "attribution" => "I am attributing this"}})
      redir_path = "/data-sets/#{meta.slug}/detail"
      assert redir_path == redirected_to(conn, :found)
      conn = get(recycle(conn), redir_path)
      response = html_response(conn, :ok)

      assert response =~ "I am a description"
      assert response =~ "I am attributing this"
    end

    @tag :auth
    test "when authenticated but not owner", %{conn: conn, admin_user: user} do
      {:ok, meta} = MetaActions.create("Test Data", user.id, "https://example.com/test-data")

      response = conn
        |> put(meta_path(conn, :do_update_description, meta.slug), %{"slug" => meta.slug, "meta" => %{"description" => "I'm a description", "attribution" => "I'm attributing this"}})
        |> response(:forbidden)

      assert response =~ "forbidden"
    end

    @tag :anon
    test "when anonymous user", %{conn: conn, reg_user: user} do
      {:ok, meta} = MetaActions.create("Test Data", user.id, "https://example.com/test-data")

      response = conn
        |> put(meta_path(conn, :do_update_description, meta.slug), %{"slug" => meta.slug, "meta" => %{"description" => "I'm a description", "attribution" => "I'm attributing this"}})
        |> response(:unauthorized)

      assert response =~ "unauthorized"
    end
  end

  describe "GET /data-sets/:slug/update/source" do

    @tag :auth
    test "when authenticated and owner", %{conn: conn, reg_user: user} do
      {:ok, meta} = MetaActions.create("Test Data", user.id, "https://example.com/test-data")

      response = conn
        |> get(meta_path(conn, :get_update_source_info, meta.slug))
        |> html_response(:ok)

      assert response =~ "Update Source Information"
    end

    @tag :auth
    test "when authenticated but not owner", %{conn: conn, admin_user: user} do
      {:ok, meta} = MetaActions.create("Test Data", user.id, "https://example.com/test-data")

      response = conn
        |> get(meta_path(conn, :get_update_source_info, meta.slug))
        |> response(:forbidden)

      assert response =~ "forbidden"
    end

    @tag :anon
    test "when anonymous user", %{conn: conn, reg_user: user} do
      {:ok, meta} = MetaActions.create("Test Data", user.id, "https://example.com/test-data")

      response = conn
        |> get(meta_path(conn, :get_update_source_info, meta.slug))
        |> response(:unauthorized)

      assert response =~ "unauthorized"
    end
  end

  describe "PUT /data-sets/:slug/update/source" do

    @tag :auth
    test "when authenticated and owner with good data", %{conn: conn, reg_user: user} do
      {:ok, meta} = MetaActions.create("Test Data", user.id, "https://example.com/test-data")

      conn = put(conn, meta_path(conn, :do_update_source_info, meta.slug), %{"slug" => meta.slug, "meta" => %{"source_url" => "https://example.com/different-data", "source_type" => "csv"}})
      redir_path = "/data-sets/#{meta.slug}/detail"
      assert redir_path == redirected_to(conn, :found)
      conn = get(recycle(conn), redir_path)
      response = html_response(conn, :ok)

      assert response =~ "different-data"
    end

    @tag :auth
    test "when authenticated and owner with bad data", %{conn: conn, reg_user: user} do
      {:ok, meta} = MetaActions.create("Test Data", user.id, "https://example.com/test-data")

      response = conn
        |> put(meta_path(conn, :do_update_source_info, meta.slug), %{"slug" => meta.slug, "meta" => %{"source_url" => "", "source_type" => "csv"}})
        |> html_response(:bad_request)

      assert response =~ "Please view and fix errors below."
    end

    @tag :auth
    test "when authenticated but not owner", %{conn: conn, admin_user: user} do
      {:ok, meta} = MetaActions.create("Test Data", user.id, "https://example.com/test-data")

      response = conn
        |> put(meta_path(conn, :do_update_source_info, meta.slug), %{"slug" => meta.slug, "meta" => %{"source_url" => "", "source_type" => "csv"}})
        |> response(:forbidden)

      assert response =~ "forbidden"
    end

    @tag :anon
    test "when anonymous user", %{conn: conn, reg_user: user} do
      {:ok, meta} = MetaActions.create("Test Data", user.id, "https://example.com/test-data")

      response = conn
        |> put(meta_path(conn, :do_update_source_info, meta.slug), %{"slug" => meta.slug, "meta" => %{"source_url" => "", "source_type" => "csv"}})
        |> response(:unauthorized)

      assert response =~ "unauthorized"
    end
  end

  describe "GET /data-sets/:slug/update/refresh" do

    @tag :auth
    test "when authenticated and owner", %{conn: conn, reg_user: user} do
      {:ok, meta} = MetaActions.create("Test Data", user.id, "https://example.com/test-data")

      response = conn
        |> get(meta_path(conn, :get_update_refresh_info, meta.slug))
        |> html_response(:ok)

      assert response =~ "Update Refresh Information"
    end

    @tag :auth
    test "when authenticated but not owner", %{conn: conn, admin_user: user} do
      {:ok, meta} = MetaActions.create("Test Data", user.id, "https://example.com/test-data")

      response = conn
        |> get(meta_path(conn, :get_update_refresh_info, meta.slug))
        |> response(:forbidden)

      assert response =~ "forbidden"
    end

    @tag :anon
    test "when anonymous user", %{conn: conn, reg_user: user} do
      {:ok, meta} = MetaActions.create("Test Data", user.id, "https://example.com/test-data")

      response = conn
        |> get(meta_path(conn, :get_update_refresh_info, meta.slug))
        |> response(:unauthorized)

      assert response =~ "unauthorized"
    end
  end

  describe "PUT /data-sets/:slug/update/refresh" do

    @tag :auth
    test "when authenticated and owner with good data", %{conn: conn, reg_user: user} do
      {:ok, meta} = MetaActions.create("Test Data", user.id, "https://example.com/test-data")

      conn = put(conn, meta_path(conn, :do_update_refresh_info, meta.slug), %{"slug" => meta.slug, "meta" => %{"refresh_rate" => "weeks", "refresh_interval" => "2", "refresh_starts_on" => "", "refresh_ends_on" => ""}})
      redir_path = "/data-sets/#{meta.slug}/detail"
      assert redir_path == redirected_to(conn, :found)
      conn = get(recycle(conn), redir_path)
      response = html_response(conn, :ok)

      assert response =~ "2 weeks"
    end

    @tag :auth
    test "when authenticated but not owner", %{conn: conn, admin_user: user} do
      {:ok, meta} = MetaActions.create("Test Data", user.id, "https://example.com/test-data")

      response = conn
        |> put(meta_path(conn, :do_update_refresh_info, meta.slug), %{"slug" => meta.slug, "meta" => %{"refresh_rate" => "weeks", "refresh_interval" => "2", "refresh_starts_on" => "", "refresh_ends_on" => ""}})
        |> response(:forbidden)

      assert response =~ "forbidden"
    end

    @tag :anon
    test "when anonymous user", %{conn: conn, reg_user: user} do
      {:ok, meta} = MetaActions.create("Test Data", user.id, "https://example.com/test-data")

      response = conn
        |> put(meta_path(conn, :do_update_refresh_info, meta.slug), %{"slug" => meta.slug, "meta" => %{"refresh_rate" => "weeks", "refresh_interval" => "2", "refresh_starts_on" => "", "refresh_ends_on" => ""}})
        |> response(:unauthorized)

      assert response =~ "unauthorized"
    end
  end

  @tag :auth
  test ":submit_for_approval", %{conn: conn, reg_user: user} do
    {:ok, meta} = MetaActions.create("test data", user.id, "https://example.com/")

    meta = MetaActions.get(meta.id)
    conn
    |> post(meta_path(conn, :submit_for_approval, meta.slug))
    |> html_response(:found)
  end
end
