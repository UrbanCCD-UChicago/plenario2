defmodule PlenarioWeb.Api.ListView do
  use PlenarioWeb, :api_view

  def render("get.json", _params) do
    %{}
  end

  def render("head.json", _params) do
    %{foo: "bar"}
  end

  def render("options.json", _params) do
    %{}
  end
end
