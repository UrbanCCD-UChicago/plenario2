alias PlenarioWeb.Api.Response


defmodule PlenarioWeb.Api.DetailView do
  use PlenarioWeb, :api_view

  def construct_response(params) do
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
      data: nil
    }
  end

  def render("get.json", params) do
    response = construct_response(params)
    if length(params[:data]) == 1 do
      %{response | data: clean(List.first(params[:data]))}
    else
      %{response | data: clean(params[:data])}
    end
  end

  defp clean(records) when is_list(records), do: clean(records, [])
  defp clean([], acc), do: Enum.reverse(acc)
  defp clean([head | tail], acc) do
    cleaned = clean(head)
    clean(tail, [cleaned | acc])
  end

  defp clean(record) when is_map(record) do
    Map.to_list(record)
    |> Enum.filter(fn {key, value} -> is_clean(key, value) end)
    |> Map.new()
  end

  defp is_clean(_, %Ecto.Association.NotLoaded{}), do: false
  defp is_clean(key, _) when key == :__meta__, do: false
  defp is_clean(_, _), do: true
end
