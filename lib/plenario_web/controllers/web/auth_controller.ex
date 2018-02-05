defmodule PlenarioWeb.Web.AuthController do
  use PlenarioWeb, :web_controller

  alias Plenario.Actions.UserActions

  alias PlenarioAuth
  alias PlenarioAuth.Guardian

  def index(conn, _) do
    changeset = UserActions.new()
    login_action = auth_path(conn, :login)
    register_action = auth_path(conn, :register)

    if Guardian.Plug.current_resource(conn) do
      redirect(conn, to: page_path(conn, :index))
    else
      render(
        conn, "index.html", changeset: changeset,
        login_action: login_action, register_action: register_action)
    end
  end

  def login(conn, %{"user" => %{"email" => email, "password" => password}}) do
    case PlenarioAuth.authenticate(email, password) do
      {:ok, user} ->
        conn
        |> Guardian.Plug.sign_in(user)
        |> put_flash(:success, "Welcome back, #{user.name}!")
        |> redirect(to: page_path(conn, :index))

      {:error, _} ->
        changeset = UserActions.new()
        login_action = auth_path(conn, :login)
        register_action = auth_path(conn, :register)

        conn
        |> put_flash(:error, "Please review errors below.")
        |> put_status(:bad_request)
        |> render(
          "index.html", changeset: changeset,
          login_action: login_action, register_action: register_action
        )
    end
  end

  def register(conn, %{"user" => %{"name" => name, "email" => email, "password" => password}}) do
    case UserActions.create(name, email, password) do
      {:ok, user} ->
        conn
        |> Guardian.Plug.sign_in(user)
        |> put_flash(:success, "Welcome, #{user.name}!")
        |> redirect(to: page_path(conn, :index))

      {:error, changeset} ->
        login_action = auth_path(conn, :login)
        register_action = auth_path(conn, :register)

        conn
        |> put_flash(:error, "Please review errors below.")
        |> put_status(:bad_request)
        |> render(
          "index.html", changeset: changeset,
          login_action: login_action, register_action: register_action
        )
    end
  end

  def logout(conn, _) do
    conn
    |> Guardian.Plug.sign_out()
    |> put_flash(:success, "Signed out.")
    |> redirect(to: page_path(conn, :index))
  end
end
