defmodule PlenarioWeb.SharedView do
  use PlenarioWeb, :shared_view

  def render_map(opts \\ []) do
    defaults = [
      map_id: "map",
      map_height: 500,
      map_center: "[41.9, -87.7]",
      map_zoom: 10,
      draw_controls: false,
      form_input_coords: "coords",
      form_input_zoom: "zoom",
      bbox: nil,
      points: nil
    ]
    assigns = Keyword.merge(defaults, opts)
    render(PlenarioWeb.SharedView, "map.html", assigns)
  end

  def render_leaflet_heatmap(observations, opts \\ []) do
    defaults = [
      map_id: "leaflet-heatmap",
      map_height: 500,
      map_center: "[41.9, -87.7]",
      map_zoom: 10
    ]
    assigns = Keyword.merge(defaults, opts)
    assigns = Keyword.merge(assigns, [observations: observations])
    render(PlenarioWeb.SharedView, "leaftlet-heatmap.html", assigns)
  end

  @red "255, 99, 132"
  @blue "54, 162, 235"
  @yellow "255, 206, 86"
  @green "75, 192, 192"
  @purple "153, 102, 255"

  def render_doughnut(key_values, opts \\ []) do
    defaults = [
      chart_id: "donut",
      height: 200
    ]
    opts = Keyword.merge(defaults, opts)

    labels = for {key, _} <- key_values, do: key
    data = for {_, value} <- key_values, do: value
    len_data = length(data)
    backgrounds =
      Stream.cycle([@red, @blue, @yellow, @green, @purple])
      |> Enum.take(len_data)
      |> Enum.map(fn c -> bgrnd_color(c) end)
    borders =
      Stream.cycle([@red, @blue, @yellow, @green, @purple])
      |> Enum.take(len_data)
      |> Enum.map(fn c -> border_color(c) end)

    assigns = Keyword.merge(opts, [
      labels: labels,
      data: data,
      backgrounds: backgrounds,
      borders: borders
    ])
    render(PlenarioWeb.SharedView, "doughnut.html", assigns)
  end

  def render_line(x_labels, key_values, opts \\ []) do
    defaults = [
      chart_id: "line",
      height: 50
    ]
    opts = Keyword.merge(defaults, opts)

    labels = for {key, _} <- key_values, do: key
    data = for {_, value} <- key_values, do: value
    len_data = length(data)
    backgrounds =
      Stream.cycle([@red, @blue, @yellow, @green, @purple])
      |> Enum.take(len_data)
      |> Enum.map(fn c -> bgrnd_color(c) end)
    borders =
      Stream.cycle([@red, @blue, @yellow, @green, @purple])
      |> Enum.take(len_data)
      |> Enum.map(fn c -> border_color(c) end)

    datasets =
      0..(len_data-1)
      |> Stream.with_index()
      |> Enum.reduce([], fn {idx, _}, acc ->
        acc ++ [Poison.encode!(%{
          data: Enum.fetch!(data, idx),
          label: Enum.fetch!(labels, idx),
          backgroundColor: Enum.fetch!(backgrounds, idx),
          borderColor: Enum.fetch!(borders, idx),
          border: 1,
          fill: true
        })]
      end)

    assigns = Keyword.merge(opts, [
      labels: x_labels,
      datasets: datasets
    ])
    render(PlenarioWeb.SharedView, "line.html", assigns)
  end

  defp bgrnd_color(base), do: "rgba(#{base}, 0.2)"

  defp border_color(base), do: "rgba(#{base}, 1)"
end
