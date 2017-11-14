defmodule Plenario2Web.PageController do
  use Plenario2Web, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
