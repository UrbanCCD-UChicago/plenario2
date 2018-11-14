defmodule PlenarioWeb.EnsureAdminPlug do
  def init(opts), do: opts

  def call(conn, _opts) do
    current_user = Guardian.Plug.current_resource(conn)
    case current_user.is_admin? do
      true -> conn
      false -> PlenarioWeb.ErrorController.handle_unauthorized(conn)
    end
  end
end
