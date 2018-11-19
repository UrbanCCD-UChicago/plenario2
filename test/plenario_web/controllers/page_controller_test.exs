defmodule PlenarioWeb.Testing.LandingPageTest do
  use PlenarioWeb.Testing.ConnCase

  describe "things i expect to see as an anonymous user" do
    @tag :anon
    test "link to login", %{conn: conn} do
      resp =
        conn
        |> get(Routes.page_path(conn, :index))
        |> html_response(:ok)

      login_href = Routes.session_path(conn, :login)
      assert resp =~ login_href
    end

    @tag :anon
    test "link to explorer app", %{conn: conn} do
      resp =
        conn
        |> get(Routes.page_path(conn, :index))
        |> html_response(:ok)

      explorer_href = Routes.page_path(conn, :explorer)
      assert resp =~ explorer_href
    end

    @tag :anon
    test "link to api docs", %{conn: conn} do
      resp =
        conn
        |> get(Routes.page_path(conn, :index))
        |> html_response(:ok)

      assert resp =~ "apiary"
    end
  end

  describe "things i expect to see as a logged in regular user" do
    @tag :auth
    test "link to user home", %{conn: conn} do
      resp =
        conn
        |> get(Routes.page_path(conn, :index))
        |> html_response(:ok)

      me_href = Routes.me_path(conn, :show)
      assert resp =~ me_href
    end

    @tag :auth
    test "link to log out", %{conn: conn} do
      resp =
        conn
        |> get(Routes.page_path(conn, :index))
        |> html_response(:ok)

      logout_href = Routes.session_path(conn, :logout)
      assert resp =~ logout_href
    end

    @tag :auth
    test "link to explorer app", %{conn: conn} do
      resp =
        conn
        |> get(Routes.page_path(conn, :index))
        |> html_response(:ok)

      explorer_href = Routes.page_path(conn, :explorer)
      assert resp =~ explorer_href
    end

    @tag :auth
    test "link to api docs", %{conn: conn} do
      resp =
        conn
        |> get(Routes.page_path(conn, :index))
        |> html_response(:ok)

      assert resp =~ "apiary"
    end
  end

  describe "things i expect to see as an admin user" do
    @tag :admin
    test "link to admin home", %{conn: conn} do
      resp =
        conn
        |> get(Routes.page_path(conn, :index))
        |> html_response(:ok)

      admin_href = Routes.page_admin_path(conn, :index)
      assert resp =~ admin_href
    end

    @tag :admin
    test "link to user home", %{conn: conn} do
      resp =
        conn
        |> get(Routes.page_path(conn, :index))
        |> html_response(:ok)

      me_href = Routes.me_path(conn, :show)
      assert resp =~ me_href
    end

    @tag :admin
    test "link to log out", %{conn: conn} do
      resp =
        conn
        |> get(Routes.page_path(conn, :index))
        |> html_response(:ok)

      logout_href = Routes.session_path(conn, :logout)
      assert resp =~ logout_href
    end

    @tag :admin
    test "link to explorer app", %{conn: conn} do
      resp =
        conn
        |> get(Routes.page_path(conn, :index))
        |> html_response(:ok)

      explorer_href = Routes.page_path(conn, :explorer)
      assert resp =~ explorer_href
    end

    @tag :admin
    test "link to api docs", %{conn: conn} do
      resp =
        conn
        |> get(Routes.page_path(conn, :index))
        |> html_response(:ok)

      assert resp =~ "apiary"
    end
  end
end
