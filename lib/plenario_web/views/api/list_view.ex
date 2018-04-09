alias PlenarioWeb.Api.Response


defmodule PlenarioWeb.Api.ListView do
  use PlenarioWeb, :api_view

  def render("get.json", %{
    count: count,
    params: params,
    total_pages: total_pages,
    total_records: total_records,
    metas: metas
  }) do
    counts = %Response.Meta.Counts{
      total_pages: total_pages,
      total_records: total_records,
      data: count
    }

    %Response{
      meta: %Response.Meta{params: params, counts: counts},
      data: metas
    }
  end

  def render("head.json", %{meta: meta}) do
    %Response{data: meta}
  end

  def render("describe.json", %{metas: metas}) do
    %Response{data: metas}
  end
end
