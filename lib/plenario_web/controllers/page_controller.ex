defmodule PlenarioWeb.PageController do
  use PlenarioWeb, :controller

  def index(conn, _params) do
    conn
    |> render("index.html")
  end
end
