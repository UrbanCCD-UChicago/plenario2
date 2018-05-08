defmodule PlenarioWeb.Api.AotView do
  use PlenarioWeb, :api_view

  alias PlenarioWeb.Api.DetailView

  def render("get.json", params) do
    response = DetailView.construct_response(params)
    %{response | data: DetailView.clean(params[:data])}
  end

  def render("head.json", params) do
    response = DetailView.construct_response(params)
    %{response | data: DetailView.clean(params[:data])}
  end

  def render("describe.json", params) do
    response = DetailView.construct_response(params)
    %{response | data: DetailView.clean(params[:data])}
  end
end
