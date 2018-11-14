defmodule PlenarioWeb.PageAdminController do
  use PlenarioWeb, :controller

  def index(conn, _), do: render conn, "index.html"
end
