defmodule Plenario2Web.PageController do
  use Plenario2Web, :controller

  def index(conn, _params) do
    conn
    |> render("index.html")
  end
end
