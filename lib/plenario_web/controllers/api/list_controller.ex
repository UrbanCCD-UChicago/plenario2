defmodule PlenarioWeb.Api.ListController do
  use PlenarioWeb, :api_controller

  def get(conn, _params) do
    render(conn, "get.json", %{})
  end

  def head(conn, _params) do
    render(conn, "head.json", %{})
  end

  def describe(conn, _params) do
    render(conn, "describe.json", %{})
  end
end
