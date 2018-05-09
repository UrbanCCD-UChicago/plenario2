defmodule PlenarioWeb.Api.MethodNotAllowedController do
	use PlenarioWeb, :api_controller

	def match(%Plug.Conn{path_info: path_info} = conn, _params) do
		routes = PlenarioWeb.Router.__routes__()
			|> Enum.map(&(&1.path))
			|> Enum.uniq()
      |> Enum.map(&(&1
      |> String.split("/")
      |> Enum.drop(1)))

		if path_info in routes do
			send_resp(conn, 405, "Method not allowed")
		else
			send_resp(conn, 404, "")
		end
	end
end
