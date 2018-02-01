defmodule PlenarioWeb.AuthController do
  use PlenarioWeb, :controller
  alias PlenarioAuth.{UserChangesets, UserActions, User, Guardian}

  def get_login(conn, _params) do
    changeset = UserChangesets.create(%User{}, %{})
    user = Guardian.Plug.current_resource(conn)
    action = auth_path(conn, :do_login)

    if user do
      redirect(conn, to: page_path(conn, :index))
    else
      render(conn, "login.html", changeset: changeset, action: action)
    end
  end

  def do_login(conn, %{"user" => %{"email_address" => email, "plaintext_password" => password}}) do
    UserActions.authenticate(email, password)
    |> login_reply(conn)
  end

  defp login_reply({:error, message}, conn) do
    conn
    |> put_flash(:error, message)
    |> redirect(to: auth_path(conn, :get_login))
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

  def get_register(conn, _params) do
    changeset = UserChangesets.create(%User{}, %{})
    action = auth_path(conn, :do_register)

    render(conn, "register.html", changeset: changeset, action: action)
  end

  def do_register(conn, %{
        "user" => %{
          "email_address" => email,
          "name" => name,
          "plaintext_password" => password,
          "organization" => org,
          "org_role" => role
        }
      }) do
    UserActions.create(name, password, email, org, role)
    |> register_reply(conn)
  end

  defp register_reply({:error, changeset}, conn) do
    conn
    |> put_flash(:error, "Please review and fix errors below.")
    |> render("register.html", changeset: changeset, action: auth_path(conn, :do_register))
  end

  defp register_reply({:ok, user}, conn) do
    conn
    |> put_flash(:success, "Welcome, #{user.name}!")
    |> Guardian.Plug.sign_in(user)
    |> redirect(to: page_path(conn, :index))
  end
end
