defmodule PlenarioWeb.Api.AotView do
  use PlenarioWeb, :api_view

  def render("get.json", params), do: PlenarioWeb.Api.DetailView.render("get.json", params)
  def render("head.json", params), do: PlenarioWeb.Api.DetailView.render("get.json", params)
  def render("describe.json", params), do: PlenarioWeb.Api.DetailView.render("get.json", params)
end
