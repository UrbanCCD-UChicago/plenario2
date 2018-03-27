defmodule PlenarioWeb.Api.ListController do
  use PlenarioWeb, :api_controller

  def get(conn, _params) do
    IO.inspect("[ListController] [get]")
    render(conn, "get.json", %{})
  end

  def head(conn, _params) do
    IO.inspect("[ListController] [HEAD]")
    render(conn, "head.json", %{})
  end

  def options(conn, _params) do
    IO.inspect("[ListController] [options]")
    render(conn, "options.json", %{})
  end
end
