defmodule PlenarioWeb.DataSetApiView do
  use PlenarioWeb, :view

  import PlenarioWeb.ApiViewUtils

  import Phoenix.View, only: [
    render_many: 3
  ]

  alias PlenarioWeb.DataSetApiView

  # list metadata

  def render("list.json", %{data_sets: data_sets, response_format: fmt, metadata: meta}),
    do: %{meta: meta, data: render_many(data_sets, DataSetApiView, "data_set.#{fmt}")}

  def render("detail.json", %{results: results, metadata: meta}) do
    data = scrub(results)
    %{meta: meta, data: data}
  end

  def render("detail.geojson", %{results: results, metadata: meta, geojson_field: field}) do
    as_geojson =
      scrub(results)
      |> Enum.map(fn record ->
        raw = Map.get(record, :"#{field.col_name}")
        geom = Geo.JSON.encode(raw)
        %{
          type: "Feature",
          geometry: geom,
          properties: record
        }
      end)

    %{meta: meta, data: as_geojson}
    |> Jason.encode!()
  end

  def render("aggregate.json", %{data: data}), do: %{
    data: data |> Enum.map(fn {count, timestamp} -> %{count: count, bucket: timestamp} end)}

  def render("data_set.json", %{data_set_api: ds}) do
    %{
      id: ds.id,
      name: ds.name,
      slug: ds.slug,
      user_id: ds.user_id,
      source_url: ds.src_url || "https://#{ds.soc_domain}/resources/#{ds.soc_4x4}.csv",
      state: ds.state,
      attribution: ds.attribution,
      description: ds.description,
      refresh_starts_on: ds.refresh_starts_on,
      refresh_ends_on: ds.refresh_ends_on,
      refresh_rate: ds.refresh_rate,
      refresh_interval: ds.refresh_interval,
      first_import: ds.first_import,
      latest_import: ds.latest_import,
      next_import: ds.next_import,
      hull: encode_geom(ds.hull),
      time_range: ds.time_range,
      num_records: ds.num_records
    }
    |> nest_related(:user, ds.user, PlenarioWeb.UserApiView, "user.json", :one)
    |> nest_related(:fields, ds.fields, PlenarioWeb.FieldApiView, "field.json")
    |> nest_related(:virtual_dates, ds.virtual_dates, PlenarioWeb.VirtualDateApiView, "virtual_date.json")
    |> nest_related(:virtual_points, ds.virtual_points, PlenarioWeb.VirtualPointApiView, "virtual_point.json")
  end

  def render("data_set.geojson", %{data_set_api: ds}) do
    %{
      type: "Feature",
      geometry: encode_geom(ds.hull),
      properties: %{
        id: ds.id,
        name: ds.name,
        slug: ds.slug,
        source: ds.src_url || "https://#{ds.soc_domain}/resources/#{ds.soc_4x4}.csv",
        state: ds.state,
        attribution: ds.attribution,
        description: ds.description,
        refresh_starts_on: ds.refresh_starts_on,
        refresh_ends_on: ds.refresh_ends_on,
        refresh_rate: ds.refresh_rate,
        refresh_interval: ds.refresh_interval,
        first_import: ds.first_import,
        latest_import: ds.latest_import,
        next_import: ds.next_import,
        time_range: ds.time_range,
        num_records: ds.num_records
      }
    }
  end

  @scrub_keys [
    :__meta__,
    :__struct__
  ]

  @scrub_values [
    Ecto.Association.NotLoaded,
    Plug.Conn
  ]

  defp scrub(records) when is_list(records), do: do_scrub(records, [])

  defp scrub(record) when is_map(record) do
    Map.to_list(record)
    |> Enum.filter(fn {key, value} -> is_clean(key, value) end)
    |> Map.new()
  end

  defp do_scrub([], acc), do: Enum.reverse(acc)

  defp do_scrub([head | tail], acc) do
    scrubbed = scrub(head)
    do_scrub(tail, [scrubbed | acc])
  end

  for key <- @scrub_keys do
    defp is_clean(unquote(key), _), do: false
  end

  for value <- @scrub_values do
    defp is_clean(_, %unquote(value){}), do: false
  end

  defp is_clean(_, %Geo.Point{}), do: true
  defp is_clean(_, %Geo.Polygon{}), do: true

  defp is_clean(_, _), do: true
end
