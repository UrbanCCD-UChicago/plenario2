defmodule Plenario2Web.MetaControllerTest do
  use Plenario2Web.ConnCase
  alias Plenario2.Actions.MetaActions
  alias Plenario2Auth.UserActions

  describe "GET /metas/create" do
    test "when authenticated", %{conn: conn} do
      UserActions.create("Test User", "password", "test@example.com")
      conn = post(conn, auth_path(conn, :login, %{"user" => %{"email_address" => "test@example.com", "plaintext_password" => "password"}}))

      response = conn
        |> get(meta_path(conn, :create))
        |> html_response(200)

      assert response =~ "Dataset name"
      assert response =~ "Source url"
    end

    test "when not authenticated", %{conn: conn} do
      response = conn
        |> get(meta_path(conn, :create))
        |> response(401)

      assert response =~ "unauthenticated"
    end
  end

  describe "POST /metas/create" do
    test "with valid data", %{conn: conn} do
      UserActions.create("Test User", "password", "test@example.com")
      conn = post(conn, auth_path(conn, :login, %{"user" => %{"email_address" => "test@example.com", "plaintext_password" => "password"}}))

      assert length(MetaActions.list()) == 0

      conn = post(conn, meta_path(conn, :do_create), %{"meta" => %{"name" => "Test Data", "source_url" => "https://example.com/test-data"}})
      assert "/datasets/list" = redir_path = redirected_to(conn, 302)
      conn = get(recycle(conn), redir_path)
      response = html_response(conn, 200)

      assert response =~ "Metas"
      assert response =~ "Test Data"

      assert length(MetaActions.list()) == 1
    end

    test "with bad data", %{conn: conn} do
      UserActions.create("Test User", "password", "test@example.com")
      conn = post(conn, auth_path(conn, :login, %{"user" => %{"email_address" => "test@example.com", "plaintext_password" => "password"}}))

      response = conn
        |> post(meta_path(conn, :do_create), %{"meta" => %{"name" => "", "source_url" => ""}})
        |> html_response(200)

      assert response =~ "Please review and fix errors below"
    end

    test "when not authenticated", %{conn: conn} do
      response = conn
        |> post(meta_path(conn, :do_create), %{"user" => %{"name" => "", "source_url" => ""}})
        |> response(401)

      assert response =~ "unauthenticated"
    end
  end

  test "GET /metas/list", %{conn: conn} do
    {:ok, user} = UserActions.create("Test User", "password", "test@example.com")
    MetaActions.create("Test Data", user.id, "https://example.com/test-data")

    response = conn
      |> get(meta_path(conn, :list))
      |> html_response(200)

    assert response =~ "Metas"
    assert response =~ "Test Data"
  end
end
