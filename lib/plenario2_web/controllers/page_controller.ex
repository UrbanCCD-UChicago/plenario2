defmodule Plenario2Web.PageController do
  use Plenario2Web, :controller
  alias Plenario2Auth.{UserChangesets, UserActions, User, Guardian}

  def index(conn, _params) do
    conn
    |> render("index.html")
  end
end
