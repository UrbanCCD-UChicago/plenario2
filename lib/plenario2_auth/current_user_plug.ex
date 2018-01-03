defmodule Plenario2Auth.CurrentUserPlug do
  @moduledoc """
  This creates a plug that assigns an authenticated user as
  the `:current_user` for a request cycle. This uses Guardian
  to store authentication cookies for a user.
  """

  alias Plenario2Auth.Guardian

  def init(opts), do: opts

  def call(conn, _opts) do
    curr_user = Guardian.Plug.current_resource(conn)
    Plug.Conn.assign(conn, :current_user, curr_user)
  end
end
