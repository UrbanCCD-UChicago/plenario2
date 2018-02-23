defmodule PlenarioAuth.ErrorHandler do
  @moduledoc """
  This module provides error handlers for Guardian and Canary. In all cases,
  the request is responded to with an appropriate response code and the
  process is halted (i.e. no other plugs will be called).
  """

  use PlenarioWeb, :web_controller

  import Plug.Conn

  @doc """
  Handles unauthenticated users -- sends a 401 resopnse. Used by Guardian.
  """
  def auth_error(conn, _, _) do
    conn
    |> put_flash(:error, "You must sign in.")
    |> redirect(to: auth_path(conn, :index, redir: conn.request_path))
  end

  @doc """
  Handles unauthorized access -- sends a 403 response. Used by Canary.
  """
  def handle_unauthorized(conn) do
    conn
    |> put_status(:forbidden)
    |> put_view(PlenarioWeb.ErrorView)
    |> render("403.html")
    |> halt()
  end

  @doc """
  Handles missing resource -- sends a 404 response. Used by Canary.
  """
  def handle_not_found(conn) do
    conn
    |> put_status(:not_found)
    |> put_view(PlenarioWeb.ErrorView)
    |> render("404.html")
  end
end
