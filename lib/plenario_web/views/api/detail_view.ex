defmodule PlenarioWeb.Api.DetailView do
  use PlenarioWeb, :api_view

  def render("get.json", _params) do
    %{}
  end

  def render("head.json", _params) do
    %{foo: "BAR"}
  end

  def render("options.json", _params) do
    %{}
  end
end
