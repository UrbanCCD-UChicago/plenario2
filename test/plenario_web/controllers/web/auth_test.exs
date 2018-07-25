defmodule PlenarioWeb.Web.Testing.AuthControllerTest do
  use PlenarioWeb.Testing.ConnCase

  describe "index" do
    @tag :auth
    test "when already authenticated", %{conn: conn} do
      conn
      |> get(auth_path(conn, :index))
      |> html_response(:found)
    end

    @tag :anon
    test "when anonymous", %{conn: conn} do
      response =
        conn
        |> get(auth_path(conn, :index))
        |> html_response(:ok)

      assert response =~ "<h1>Log In</h1>"
      assert response =~ "<h1>Sign Up</h1>"
    end
  end

  describe "login" do
    @tag :auth
    test "with good credentials", %{conn: conn, reg_user: user} do
      params = %{
        "user" => %{
          "email" => user.email,
          "password" => "password"  # omg so secure!
        }
      }

      conn
      |> post(auth_path(conn, :login, params))
      |> html_response(:found)
    end

    @tag :anon
    test "with bad credentials", %{conn: conn} do
      params = %{
        "user" => %{
          "email" => "justsomeperson@nowhere.com",
          "password" => "whatever"
        }
      }

      conn
      |> post(auth_path(conn, :login, params))
      |> html_response(:bad_request)
    end
  end

  describe "register" do
    @tag :anon
    test "as a new user", %{conn: conn} do
      params = %{
        "user" => %{
          "email" => "justsomeperson@nowhere.com",
          "password" => "whatever",
          "name" => "some person"
        }
      }

      conn
      |> post(auth_path(conn, :register, params))
      |> html_response(:found)
    end

    @tag :auth
    test "with a taken email address", %{conn: conn, reg_user: user} do
      params = %{
        "user" => %{
          "email" => user.email,
          "password" => "whatever",
          "name" => "some person"
        }
      }

      conn
      |> post(auth_path(conn, :register, params))
      |> html_response(:bad_request)
    end
  end

  @tag :auth
  test "logout", %{conn: conn} do
    conn
    |> post(auth_path(conn, :logout))
    |> html_response(:found)
  end
end
