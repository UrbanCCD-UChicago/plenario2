defmodule PlenarioWeb.Api.MethodNotAllowedController do
  use PlenarioWeb, :api_controller

  def match(%Plug.Conn{path_info: path_info} = conn, _params) do
    routes =
      PlenarioWeb.Router.__routes__()
      |> Enum.map(&(&1.path))
      |> Enum.uniq()
      |> Enum.map(&(&1
      |> String.split("/")
      |> Enum.drop(1)))

    if path_info in routes do
      conn
      |> put_req_header("accept", "application/vnd.api+json")
      |> Explode.with(403, "Method not allowed")
    else
      conn
      |> put_req_header("accept", "application/vnd.api+json")
      |> Explode.with(404, "Not found")
    end
  end
end
