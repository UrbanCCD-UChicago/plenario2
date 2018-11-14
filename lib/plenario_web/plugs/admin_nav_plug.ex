defmodule PlenarioWeb.AdminNavPlug do
  import Plug.Conn

  alias Plug.Conn

  def admin_nav?(%Conn{request_path: path} = conn, _), do: assign(conn, :admin_nav?, String.starts_with?(path, "/admin"))
end
