defmodule Plenario2Web.AuthController do
  use Plenario2Web, :controller
  alias Plenario2Auth.{UserChangesets, UserActions, User, Guardian}

  def index(conn, _params) do
    changeset = UserChangesets.create(%User{}, %{})
    user = Guardian.Plug.current_resource(conn)
    action = auth_path(conn, :login)

    # TODO: at some point this should just be redirected to "/" when the user is already logged in

    conn
    |>render("login.html", changeset: changeset, action: action, user: user)
  end

  def login(conn, %{"user" => %{"email_address" => email, "plaintext_password" => password}}) do
    UserActions.authenticate(email, password)
    |> login_reply(conn)
  end

  defp login_reply({:error, message}, conn) do
    conn
    |> put_flash(:error, message)
    |> redirect(to: auth_path(conn, :index))
  end

  defp login_reply({:ok, user}, conn) do
    conn
    |> put_flash(:success, "Welcome back, #{user.name}!")
    |> Guardian.Plug.sign_in(user)
    |> redirect(to: page_path(conn, :index))
  end

  def logout(conn, _params) do
    conn
    |> Guardian.Plug.sign_out()
    |> redirect(to: page_path(conn, :index))
  end

  def register(conn, _params) do
    changeset = UserChangesets.create(%User{}, %{})
    action = auth_path(conn, :do_register)

    conn
    |> render("register.html", changeset: changeset, action: action)
  end

  def do_register(conn, %{"user" => %{"email_address" => email, "name" => name, "plaintext_password" => password, "organization" => org, "org_role" => role}}) do
    UserActions.create(name, password, email, org, role)
    |> register_reply(conn)
  end

  defp register_reply({:error, _changeset}, conn) do
    conn
    |> put_flash(:error, "Email address already registered.")
    |> redirect(to: auth_path(conn, :register))
  end

  defp register_reply({:ok, user}, conn) do
    conn
    |> put_flash(:success, "Welcome, #{user.name}!")
    |> Guardian.Plug.sign_in(user)
    |> redirect(to: page_path(conn, :index))
  end
end
