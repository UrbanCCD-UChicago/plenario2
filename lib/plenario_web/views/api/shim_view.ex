defmodule PlenarioWeb.Api.ShimView do
  def render("get.json", params), do: PlenarioWeb.Api.ListView.render("get.json", params)
end