defmodule PlenarioAuth.AdminPlug do
  @moduledoc """
  This creates a plug to be used in authenticating and authorizing users
  for the /admin paths of the website. If the requesting user is not
  an admin or is anonymous then this will bounce the request.
  """

  alias PlenarioAuth.Guardian
  alias PlenarioAuth.ErrorHandler

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
