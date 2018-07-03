defmodule PlenarioWeb.Api.ShimView do
  require Logger

  alias Plenario.Schemas.Meta
  import PlenarioWeb.Api.DetailView, only: [clean: 1]

  # todo(heyzoos) refactor what gets passed in as params
  #   - Currently I just toss the whole kitchen sink at you and say:
  #     "From this pile of shit construct a meaningful response"
  #   - It would be nice if we formalized this as a struct with just
  #     the necessary information
  def render("datasets.json", params) do
    render("detail.json", %{params | data: translate_meta(params[:data])})
  end

  def render("detail.json", params) do 
    %{
      meta: %{
        message: "",
        total: params[:total_records],
        query: params[:params],
        status: "ok"
      },
      objects: clean(params[:data])
    }
  end

  def translate_metas(metas) do
    columns = meta.fields |> format_columns() |> Enum.sort()
    location = Enum.find(meta.virtual_point_fields, fn field -> not is_nil(field) end)
    observed_date = Enum.find(columns, fn field -> field.type == "DATE" end)

    Enum.map(metas, fn meta ->
      %{
        bbox: meta.bbox,
        columns: columns,
        latitude: nil,
        obs_from: meta.time_range["lower"],
        observed_date: observed_date,
        obs_to: meta.time_range["upper"]
        view_url: nil,
        description: meta.description,
        attribution: meta.attribution,
        longitude: nil,
        source_url: meta.source_url,
        human_name: meta.,
        dataset_name: meta.slug,
        date_added: meta.inserted_at,
        last_update: meta.latest_import,
        update_freq: meta.refresh_rate,
        location: location
      }
    end)
  end

  #   - Need to select first location column
  #   -   Sort and grab
  #   - Need to select first datetime column
  #   -   Sort and grab

  def translate_meta(meta = %Meta{}) do
    %{
      bbox: meta.bbox,
      latitude: meta.
    }
  end

  # This needs to map to expected types
  def format_columns(columns) do
    Enum.map(columns, fn column -> 
      %{field_name: column.name, field_type: column.type}
    end)
  end
end