alias PlenarioWeb.Api.Response


defmodule PlenarioWeb.Api.DetailView do
  use PlenarioWeb, :api_view

  def render("get.json", params) do
    counts = %Response.Meta.Counts{
      total_pages: params[:total_pages],
      total_records: params[:total_records],
      data: params[:data_count]
    }

    %Response{
      meta: %Response.Meta{
        params: params[:params],
        counts: counts
      },
      data: params[:data]
    }
  end

  def render("head.json", %{record: record}) do
    %Response{data: record}
  end
end
