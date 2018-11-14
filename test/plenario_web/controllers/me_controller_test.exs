defmodule PlenarioWeb.Testing.MeControllerTest do
  use PlenarioWeb.Testing.ConnCase

  import Plenario.Testing.DataCase

  describe "on the landing page i expect to see" do
    @tag :auth
    test "a link to update my information", %{conn: conn} do
      resp =
        conn
        |> get(Routes.me_path(conn, :show))
        |> html_response(:ok)

      update_href = Routes.me_path(conn, :edit)
      assert resp =~ update_href
    end

    @tag :auth
    test "a listing of my data sets", %{conn: conn, user: user} do
      data_set = create_data_set(%{user: user})

      resp =
        conn
        |> get(Routes.me_path(conn, :show))
        |> html_response(:ok)

      assert resp =~ data_set.name

      edit_href = Routes.data_set_path(conn, :show, data_set)
      assert resp =~ edit_href
    end

    @tag :auth
    test "a link to create a new data set", %{conn: conn} do
      resp =
        conn
        |> get(Routes.me_path(conn, :show))
        |> html_response(:ok)

      new_href = Routes.data_set_path(conn, :new)
      assert resp =~ new_href
    end
  end

  describe "update my informaiton" do
    @tag :auth
    test "change my password", %{conn: conn, user: user} do
      new_password = "new password"

      conn =
        conn
        |> put(Routes.me_path(conn, :update, %{"user" => %{"password" => new_password}}))

      redir_path = redirected_to(conn, 302)

      conn =
        conn
        |> recycle()
        |> get(redir_path)

      assert html_response(conn, :ok)
      assert Plenario.UserActions.authenticate(user.email, new_password)
    end
  end
end
