defmodule Plenario2Auth.ErrorHandler do
  import Plug.Conn

  # not authenticated -- used by guardian
  def auth_error(conn, _, _) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(:unauthorized, "unauthorized")
    |> halt()
  end

  # user/resource authorization fail -- canary
  def handle_unauthorized(conn) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(:forbidden, "forbidden")
    |> halt()
  end

  # resource not found -- canary
  def handle_not_found(conn) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(:not_found, "not found")
    |> halt()
  end
end
