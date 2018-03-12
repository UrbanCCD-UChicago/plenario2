defmodule Plenario.Plugs.AssertIdIsInteger do
  import Plug.Conn
  import Phoenix.Controller
  use PlenarioWeb, :web_controller

  def init(default), do: default

  def call(%Plug.Conn{params: %{"id" => id}} = conn, _default) do
    if is_integer(id) do
      conn
    else
      case Integer.parse(id) do
        {_, _} ->
          conn
        :error ->
          do_404(conn)
          |> halt()
      end
    end
  end

  def call(%Plug.Conn{} = conn, _default) do
    conn
  end
end