alias PlenarioWeb.Api.Response


defmodule PlenarioWeb.Api.ListView do
  use PlenarioWeb, :api_view

  def render("get.json", %{metas: metas}) do
    %Response{data: metas}
  end

  def render("head.json", %{meta: meta}) do
    %Response{data: meta}
  end

  def render("describe.json", %{metas: metas}) do
    %Response{data: metas}
  end
end
