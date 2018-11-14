defmodule PlenarioWeb.Testing.ScopesTest do
  use PlenarioWeb.Testing.ConnCase

  import Plenario.Testing.DataCase

  describe "publicly viewable pages" do
    @tag :anon
    test "are accessible to anons", %{conn: conn} do
      conn
      |> get(Routes.page_path(conn, :index))
      |> html_response(:ok)
    end

    @tag :auth
    test "are accessible to authenticated users", %{conn: conn} do
      conn
      |> get(Routes.page_path(conn, :index))
      |> html_response(:ok)
    end

    @tag :admin
    test "are accessible to admin users", %{conn: conn} do
      conn
      |> get(Routes.page_path(conn, :index))
      |> html_response(:ok)
    end
  end

  describe "authenticated user pages" do
    @tag :anon
    test "are inaccessible to anons", %{conn: conn} do
      conn
      |> get(Routes.data_set_path(conn, :new))
      |> html_response(:unauthorized)
    end

    @tag :auth
    test "are accessible to authenticated users", %{conn: conn} do
      conn
      |> get(Routes.data_set_path(conn, :new))
      |> html_response(:ok)
    end

    @tag :admin
    test "are accessible to admin users", %{conn: conn} do
      conn
      |> get(Routes.data_set_path(conn, :new))
      |> html_response(:ok)
    end
  end

  describe "authorized user pages" do
    @tag :anon
    test "are inaccessible to anons", %{conn: conn} do
      user = create_user(%{}, username: "Admin User", email: "admin@example.com")
      data_set = create_data_set(%{user: user})

      conn
      |> get(Routes.data_set_path(conn, :edit, data_set))
      |> html_response(:unauthorized)
    end

    @tag :auth
    test "are inaccessible to authenticated non-owner users", %{conn: conn} do
      user = create_user(%{}, username: "Admin User", email: "admin@example.com")
      data_set = create_data_set(%{user: user})

      conn
      |> get(Routes.data_set_path(conn, :edit, data_set))
      |> html_response(:forbidden)
    end

    @tag :auth
    test "are accessible to authenticated owning users", %{conn: conn, user: user} do
      data_set = create_data_set(%{user: user})

      conn
      |> get(Routes.data_set_path(conn, :edit, data_set))
      |> html_response(:ok)
    end

    @tag :admin
    test "are accessible to admin users", %{conn: conn} do
      user = create_user()
      data_set = create_data_set(%{user: user})

      conn
      |> get(Routes.data_set_path(conn, :edit, data_set))
      |> html_response(:ok)
    end
  end

  describe "admin pages" do
    @tag :anon
    test "are inaccessible to anons", %{conn: conn} do
      conn
      |> get(Routes.user_admin_path(conn, :index))
      |> html_response(:unauthorized)
    end

    @tag :auth
    test "are inaccessible to authenticated regular users", %{conn: conn} do
      conn
      |> get(Routes.user_admin_path(conn, :index))
      |> html_response(:forbidden)
    end

    @tag :admin
    test "are accessible to admin users", %{conn: conn} do
      conn
      |> get(Routes.user_admin_path(conn, :index))
      |> html_response(:ok)
    end
  end
end
