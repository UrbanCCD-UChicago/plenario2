alias PlenarioWeb.Api.Response


defmodule PlenarioWeb.Api.DetailView do
  use PlenarioWeb, :api_view

  def render("get.json", params) do
    counts = %Response.Meta.Counts{
      total_pages: params[:total_pages],
      total_records: params[:total_records],
      data: params[:data_count]
    }

    links = %Response.Meta.Links{
      previous: params[:links][:previous],
      current: params[:links][:current],
      next: params[:links][:next]
    }

    %Response{
      meta: %Response.Meta{
        params: params[:params],
        counts: counts,
        links: links
      },
      data: params[:data]
    }
  end

  def render("head.json", %{record: nil}) do
    counts = %Response.Meta.Counts{
      total_pages: 1,
      total_records: 1,
      data: 0
    }

    %Response{
      meta: %Response.Meta{
        counts: counts
      }
    }
  end

  def render("head.json", %{record: record}) do
    counts = %Response.Meta.Counts{
      total_pages: 1,
      total_records: 1,
      data: 1
    }

    %Response{
      meta: %Response.Meta{
        counts: counts
      },
      data: record
    }
  end
end
