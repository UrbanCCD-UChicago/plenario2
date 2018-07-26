defmodule PlenarioWeb.Api.MethodNotAllowedController do
  use PlenarioWeb, :api_controller

  import PlenarioWeb.Api.Utils, only: [halt_with: 2]

  def match(%Plug.Conn{path_info: path_info} = conn, _params) do
    routes =
      PlenarioWeb.Router.__routes__()
      |> Enum.map(&(&1.path))
      |> Enum.uniq()
      |> Enum.map(&(&1
      |> String.split("/")
      |> Enum.drop(1)))

    if path_info in routes do
      conn |> halt_with(:method_not_allowed)
    else
      conn |> halt_with(:not_found)
    end
  end
end
