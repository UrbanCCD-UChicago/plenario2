defmodule PlenarioWeb.Api.DetailView do
  @moduledoc """
  """

  use PlenarioWeb, :api_view

  def render("get.json", opts) do
    %{
      meta: %{
        links: opts[:links],
        counts: opts[:counts],
        params: opts[:params]
      },
      data: opts[:data] |> clean()
    }
  end

  def render("head.json", opts) do
    %{
      meta: %{
        links: opts[:links],
        counts: opts[:counts],
        params: opts[:params]
      },
      data: opts[:data] |> clean() |> Enum.take(1)
    }
  end

  def render("describe.json", opts) do
    %{
      meta: %{
        links: opts[:links],
        counts: opts[:counts],
        params: opts[:params]
      },
      data: opts[:data] |> clean()
    }
  end

  # TODO: shouldn't all these be private? i think there's one external call somewhere though.

  def clean(records) when is_list(records) do
    clean(records, [])
  end

  def clean(record) when is_map(record) do
    Map.to_list(record)
    |> Enum.filter(fn {key, value} -> is_clean(key, value) end)
    |> Map.new()
  end

  defp clean([], acc) do
    Enum.reverse(acc)
  end

  defp clean([head | tail], acc) do
    cleaned = clean(head)
    clean(tail, [cleaned | acc])
  end

  defp is_clean(_, %Ecto.Association.NotLoaded{}), do: false
  defp is_clean(_, %Plug.Conn{}), do: false

  defp is_clean(key, _)
       when key in [
              :__meta__,
              :__struct__,
              :id,
              :inserted_at,
              :updated_at,
              :source_type,
              :table_name,
              :state,
              :user_id
            ],
       do: false

  defp is_clean(_, _), do: true
end
