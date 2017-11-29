defmodule Plenario2Auth.CurrentUserPlug do
  alias Plenario2Auth.Guardian

  def init(opts), do: opts

  def call(conn, _opts) do
    curr_user = Guardian.Plug.current_resource(conn)
    Plug.Conn.assign(conn, :current_user, curr_user)
  end
end
