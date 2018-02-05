defmodule PlenarioWeb.Web.PageController do
  use PlenarioWeb, :web_controller

  def index(conn, _), do: render(conn, "index.html")

  def explorer(conn, _), do: render(conn, "explorer.html")

  def aot_explorer(conn, _), do: render(conn, "aot-explorer.html")
end
