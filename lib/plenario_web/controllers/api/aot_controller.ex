defmodule PlenarioWeb.Api.AotController do
  use PlenarioWeb, :api_controller

  def get(conn, _params) do
    PlenarioWeb.Api.DetailController.get(conn, %{"slug" => "array_of_thing_chicago"})
  end

  def head(conn, _params) do
    PlenarioWeb.Api.DetailController.head(conn, %{"slug" => "array_of_things_chicago"})
  end

  def describe(conn, _params) do
    PlenarioWeb.Api.DetailController.describe(conn, %{"slug" => "array_of_things_chicago"})
  end
end
