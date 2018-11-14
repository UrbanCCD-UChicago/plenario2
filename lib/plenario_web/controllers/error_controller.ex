defmodule PlenarioWeb.ErrorController do
  use PlenarioWeb, :controller

  alias PlenarioWeb.ErrorView

  def auth_error(conn, _ \\ {}, _ \\ %{}), do: conn |> put_status(:unauthorized) |> put_view(ErrorView) |> render("401.html") |> halt()

  def handle_unauthorized(conn, _ \\ %{}), do: conn |> put_status(:forbidden) |> put_view(ErrorView) |> render("403.html") |> halt()

  def handle_not_found(conn, _ \\ %{}), do: conn |> put_status(:not_found) |> put_view(ErrorView) |> render("404.html") |> halt()
end
