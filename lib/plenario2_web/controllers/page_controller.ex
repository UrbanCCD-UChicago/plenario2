defmodule Plenario2Web.PageController do
  use Plenario2Web, :controller
  alias Plenario2Auth.{UserChangesets, UserActions, User, Guardian}

  def index(conn, _params) do
    changest = UserChangesets.create(%User{}, %{})

    maybe_user = Guardian.Plug.current_resource(conn)
    message = if maybe_user != nil do
      "Someone is logged in"
    else
      "No one is logged in"
    end

    conn
    |> put_flash(:info, message)
    |> render("index.html", changeset: changest, action: page_path(conn, :login), maybe_user: maybe_user)
  end

  def login(conn, %{"user" => %{"email_address" => email, "plaintext_password" => password}}) do
    UserActions.authenticate(email, password)
    |> login_reply(conn)
  end

  defp login_reply({:error, error}, conn) do
    conn
    |> put_flash(:error, error)
    |> redirect(to: "/")
  end

  defp login_reply({:ok, user}, conn) do
    conn
    |> put_flash(:success, "Welcome back, #{user.name}!")
    |> Guardian.Plug.sign_in(user)
    |> redirect(to: "/")
  end

  def logout(conn, _) do
    conn
    |> Guardian.Plug.sign_out()
    |> redirect(to: page_path(conn, :login))
  end

  def secret(conn, _) do
    render(conn, "secret.html")
  end
end
