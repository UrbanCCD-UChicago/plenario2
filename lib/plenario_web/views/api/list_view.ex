alias PlenarioWeb.Api.Response


defmodule PlenarioWeb.Api.ListView do
  use PlenarioWeb, :api_view

  def render("get.json", params) do
    PlenarioWeb.Api.DetailView.render("get.json", params)
  end

  def render("head.json", %{meta: meta}) do
    %Response{data: meta}
  end
end
