defmodule PlenarioWeb.Web.Testing.MeControllerTest do
  use PlenarioWeb.Testing.ConnCase

  alias Plenario.Actions.UserActions

  @tag :auth
  test "index", %{conn: conn} do
    conn
    |> get(me_path(conn, :index))
    |> html_response(:ok)
  end

  @tag :auth
  test "edit", %{conn: conn} do
    conn
    |> get(me_path(conn, :edit))
    |> html_response(:ok)
  end

  describe "update" do
    @tag :auth
    test "with good inputs", %{conn: conn, reg_user: user} do
      new_bio = "my new bio"
      params = %{
        "user" => %{
          "name" => user.name,
          "email" => user.email,
          "bio" => new_bio
        }
      }

      conn
      |> put(me_path(conn, :update, params))
      |> html_response(:found)

      user = UserActions.get(user.id)
      assert user.bio == new_bio
    end

    @tag :auth
    test "with bad inputs", %{conn: conn} do
      params = %{
        "user" => %{
          "name" => "",
          "email" => "",
          "bio" => ""
        }
      }

      conn
      |> put(me_path(conn, :update, params))
      |> html_response(:bad_request)
    end
  end

  @tag :auth
  test "edit password", %{conn: conn} do
    conn
    |> get(me_path(conn, :edit_password))
    |> html_response(:ok)
  end

  describe "update password" do
    @tag :auth
    test "with a good password", %{conn: conn} do
      params = %{
        "passwd" => %{
          "old" => "password",
          "new" => "P@ssw0rd",
          "confirm" => "P@ssw0rd"
        }
      }

      conn
      |> put(me_path(conn, :update_password, params))
      |> html_response(:found)
    end

    @tag :auth
    test "with a bad password", %{conn: conn} do
      params = %{
        "passwd" => %{
          "old" => "password",
          "new" => "",
          "confirm" => ""
        }
      }

      conn
      |> put(me_path(conn, :update_password, params))
      |> html_response(:bad_request)
    end

    @tag :auth
    test "with an incorrect current password", %{conn: conn} do
      params = %{
        "passwd" => %{
          "old" => "i totally forgot it",
          "new" => "P@ssw0rd",
          "confirm" => "P@ssw0rd"
        }
      }

      conn
      |> put(me_path(conn, :update_password, params))
      |> html_response(:bad_request)
    end

    @tag :auth
    test "with mismatched new and confirmed passwords", %{conn: conn} do
      params = %{
        "passwd" => %{
          "old" => "password",
          "new" => "P@ssw0rd",
          "confirm" => "i'm not filling in my password again"
        }
      }

      conn
      |> put(me_path(conn, :update_password, params))
      |> html_response(:bad_request)
    end
  end

  test "/me redirects an unautorized user to login", %{conn: conn} do
    conn
    |> get(me_path(conn, :index, %{}))
    |> html_response(302)
  end
end
