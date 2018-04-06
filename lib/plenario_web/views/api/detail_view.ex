alias PlenarioWeb.Api.Response


defmodule PlenarioWeb.Api.DetailView do
  use PlenarioWeb, :api_view

  def render("get.json", %{records: records}) do
    %Response{data: records}
  end

  def render("head.json", %{record: record}) do
    %Response{data: record}
  end

  def render("describe.json", %{records: records}) do
    %Response{data: records}
  end
end
