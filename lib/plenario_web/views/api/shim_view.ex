defmodule PlenarioWeb.Api.ShimView do
  require Logger

  import PlenarioWeb.Api.DetailView, only: [clean: 1]

  alias Plenario.TsRange

  @doc """
  Chooses the right view method for `render` calls coming from the V2 API
  controllers. We can check who is calling this `render` method by inspecting
  the `:phoenix_controller` key in the provided `Conn` struct.
  """
  def render("get.json", params) do
    case params[:conn].private[:phoenix_controller] do
      PlenarioWeb.Api.DetailController -> render("detail.json", params)
      PlenarioWeb.Api.ListController -> render("datasets.json", params)
    end
  end

  # todo(heyzoos) refactor what gets passed in as params
  #   - Currently I just toss the whole kitchen sink at you and say:
  #     "From this pile of shit construct a meaningful response"
  #   - It would be nice if we formalized this as a struct with just
  #     the necessary information
  def render("datasets.json", params) do
    render("detail.json", %{params | data: translate_metas(params[:data])})
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
    Enum.map(metas, fn meta ->
      columns =
        meta.fields
        |> format_columns()
        |> Enum.sort()

      location = Enum.find(meta.virtual_points, fn field -> not is_nil(field) end)
      location_name = if location do location.name else nil end

      observed_date = Enum.find(columns, fn field -> field[:field_type] == "TIMESTAMP" end)
      observed_date_name = if observed_date do observed_date[:field_name] else nil end

      {obs_from, obs_to} =
        case meta.time_range do
          nil ->
            {nil, nil}

          %TsRange{lower: lower, upper: upper} ->
            {lower, upper}
        end

      %{
        bbox: meta.bbox,
        columns: columns,
        latitude: nil,
        obs_from: obs_from,
        observed_date: observed_date_name,
        obs_to: obs_to,
        view_url: nil,
        description: meta.description,
        attribution: meta.attribution,
        longitude: nil,
        source_url: meta.source_url,
        human_name: meta.name,
        dataset_name: meta.slug,
        date_added: meta.inserted_at,
        last_update: meta.latest_import,
        update_freq: meta.refresh_rate,
        location: location_name
      }
    end)
  end

  def format_columns(columns) do
    Enum.map(columns, fn column ->
      %{field_name: column.name, field_type: String.upcase(column.type)}
    end)
  end
end
