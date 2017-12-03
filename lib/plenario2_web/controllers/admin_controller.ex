defmodule Plenario2Web.AdminController do
  use Plenario2Web, :controller

  def index(conn, _) do
    render(conn, "index.html")
  end
end
