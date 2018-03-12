defmodule Plenario.Plugs.AssertIdIsInteger do
  import Plug.Conn
  import Phoenix.Controller

  def init(default), do: default

  def call(%Plug.Conn{params: %{"id" => id}} = conn, _default) do
    if is_integer(id) do
      conn
    else
      case Integer.parse(id) do
        {_, _} ->
          conn
        :error ->
          put_status(conn, 404)
          |> render(PlenarioWeb.ErrorView, "404.html")
      end
    end
  end

  def call(%Plug.Conn{} = conn, _default) do
    conn
  end
end