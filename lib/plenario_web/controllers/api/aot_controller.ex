defmodule PlenarioWeb.Api.AotController do
  use PlenarioWeb, :api_controller

  def get(conn, _params) do
    PlenarioWeb.Api.DetailController.get(conn, %{"slug" => "array-of-things-chicago"})
  end

  def head(conn, _params) do
    PlenarioWeb.Api.DetailController.head(conn, %{"slug" => "array-of-things-chicago"})
  end

  def describe(conn, _params) do
    PlenarioWeb.Api.DetailController.describe(conn, %{"slug" => "array-of-things-chicago"})
  end
end
