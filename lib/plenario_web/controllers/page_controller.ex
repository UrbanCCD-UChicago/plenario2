defmodule PlenarioWeb.PageController do
  use PlenarioWeb, :controller

  import Plug.Conn

  def assign_s3_path(conn, _opts) do
    assign(conn, :s3_asset_path, "https://s3.amazonaws.com/plenario2-assets")
  end

  plug :assign_s3_path

  def index(conn, _), do: render conn, "index.html"

  def explorer(conn, _), do: render conn, "explorer.html"
end
