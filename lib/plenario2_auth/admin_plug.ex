defmodule Plenario2Auth.AdminPlug do
  alias Plenario2Auth.Guardian
  alias Plenario2Auth.ErrorHandler

  def init(opts), do: opts

  def call(conn, _opts) do
    curr_user = Guardian.Plug.current_resource(conn)
    if not curr_user.is_admin do
      ErrorHandler.handle_unauthorized(conn)
    else
      conn
    end
  end
end
