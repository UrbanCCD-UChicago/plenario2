defmodule PlenarioWeb.FieldPlugs do
  import Plug.Conn

  alias Plug.Conn

  def assign_dsid(%Conn{params: %{"data_set_id" => dsid}} = conn, _opts), do: assign(conn, :dsid, dsid)
end
