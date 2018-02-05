defmodule PlenarioWeb.Admin.AdminPageController do
  use PlenarioWeb, :admin_controller

  def index(conn, _), do: render(conn, "index.html")
end
