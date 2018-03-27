defmodule PlenarioWeb.Api.AotController do
  use PlenarioWeb, :api_controller

  def get(conn, _params) do
    render(conn, "get.json", %{})
  end

  def head(conn, _params) do
    render(conn, "head.json", %{})
  end

  def options(conn, _params) do
    render(conn, "options.json", %{})
  end
end
