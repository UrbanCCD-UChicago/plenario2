defmodule PlenarioWeb.SessionController do
  use PlenarioWeb, :controller

  alias Plenario.{
    User,
    UserActions,
    Auth.Guardian
  }

  alias Plug.Conn

  def login(conn, %{"user" => %{"email" => email, "password" => password}}) do
    UserActions.authenticate(email, password)
    |> do_login(conn)
  end

  def login(conn, _) do
    changeset = User.changeset(%User{}, %{})
    maybe_user = Guardian.Plug.current_resource(conn)
    if maybe_user do
      redirect(conn, to: get_redirect(conn))
    else
      render conn, "login.html",
        changeset: changeset,
        login_action: Routes.session_path(conn, :login),
        register_action: Routes.session_path(conn, :register)
    end
  end

  defp do_login({:ok, user}, conn) do
    conn
    |> put_flash(:success, "Welcome back!")
    |> Guardian.Plug.sign_in(user)
    |> redirect(to: get_redirect(conn))
  end

  defp do_login({:error, reason}, conn) do
    changeset = User.changeset(%User{}, %{})

    conn
    |> put_flash(:error, to_string(reason))
    |> put_status(:bad_request)
    |> render("login.html",
      changeset: changeset,
      login_action: Routes.session_path(conn, :login),
      register_action: Routes.session_path(conn, :register)
    )
  end

  def register(conn, %{"user" => %{"username" => _, "password" => _} = form}) do
    UserActions.create(form)
    |> do_register(conn)
  end

  def register(conn, _) do
    changeset = User.changeset(%User{}, %{})
    maybe_user = Guardian.Plug.current_resource(conn)
    if maybe_user do
      redirect(conn, to: get_redirect(conn))
    else
      render conn, "register.html",
        changeset: changeset,
        register_action: Routes.session_path(conn, :register),
        login_action: Routes.session_path(conn, :login)
    end
  end

  defp do_register({:ok, user}, conn) do
    conn
    |> Guardian.Plug.sign_in(user)
    |> put_flash(:success, "Welcome!")
    |> redirect(to: get_redirect(conn))
  end

  defp do_register({:error, changeset}, conn) do
    conn
    |> put_status(:bad_request)
    |> put_error_flashes(changeset)
    |> render("register.html",
      changeset: changeset,
      register_action: Routes.session_path(conn, :register),
      login_action: Routes.session_path(conn, :login)
    )
  end

  def logout(conn, _) do
    conn
    |> Guardian.Plug.sign_out()
    |> redirect(to: get_redirect(conn))
  end

  defp get_redirect(%Conn{params: %{"redirect" => r}}), do: r
  defp get_redirect(conn), do: Routes.page_path(conn, :index)
end
