defmodule Plenario2Web.UserControllerTest do
  use Plenario2Web.ConnCase, async: true
  alias Plenario2.Actions.MetaActions
  alias Plenario2Auth.UserActions

  describe ":index" do
    test "as anonymous", %{conn: conn} do
      conn
      |> get(user_path(conn, :index))
      |> response(:unauthorized)
    end

    test "as a logged in user", %{conn: conn} do
      {:ok, user} = UserActions.create("test", "password", "test@example.com")
      conn = post(conn, auth_path(conn, :do_login, %{"user" => %{"email_address" => "test@example.com", "plaintext_password" => "password"}}))

      conn
      |> get(user_path(conn, :index))
      |> html_response(:ok)
    end
  end
end
