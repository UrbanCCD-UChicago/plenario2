defmodule PlenarioWeb.Api.ShimView do
  @moduledoc """
  """

  use PlenarioWeb, :api_view

  alias Plenario.Schemas.Meta

  def render("datasets.json", opts) do
    data =
      opts[:data]
      |> Enum.map(fn meta ->
        %{
          attribution: meta.attribution,
          description: meta.description,
          view_url: "/v1/api/detail?dataset_name=#{meta.slug}",
          columns: render_fields(meta),
          obs_from: "#{meta.time_range.lower}",
          bbox: meta.bbox,
          human_name: meta.name,
          obs_to: "#{meta.time_range.upper}",
          source_url: meta.source_url,
          dataset_name: meta.slug,
          update_freq: Meta.get_refresh_cadence(meta)
        }
      end)

    %{
      meta: %{
        status: "ok",
        query: %{},
        message: [],
        total: length(data)
      },
      objects: data
    }
  end

  def render("fields.json", opts) do
    meta = opts[:meta]
    fields = render_fields(meta)

    %{
      meta: %{
        status: "ok",
        query: %{},
        message: [],
        total: length(fields)
      },
      objects: fields
    }
  end

  def render("detail.json", opts) do
    %{
      meta: %{
        status: "ok",
        query: %{},
        message: [],
        total: length(opts[:data])
      },
      objects: opts[:data] |> clean()
    }
  end

  # HELPERS

  defp render_fields(meta) do
    fields =
      meta.fields
      |> Enum.map(fn f -> %{field_type: f.type, field_name: f.name} end)

    dates =
      meta.virtual_dates
      |> Enum.map(fn d -> %{field_type: "timestamp", field_name: d.name} end)

    points =
      meta.virtual_points
      |> Enum.map(fn p -> %{field_type: "geometry(point, 4326)", field_name: p.name} end)

    fields ++ dates ++ points
  end
end
