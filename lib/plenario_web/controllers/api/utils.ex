defmodule PlenarioWeb.Api.Utils do
  import Ecto.Query

  import Geo.PostGIS

  import Geo.PostGIS,
    only: [
      st_intersects: 2,
      st_within: 2
    ]

  import Plenario.Queries.Utils,
    only: [
      timestamp_within: 2,
      tsrange_intersects: 2
    ]

  import PlenarioWeb.Router.Helpers,
    only: [
      detail_url: 4,
      list_url: 3,
      aot_url: 3
    ]

  import Plug.Conn,
    only: [
      put_resp_header: 3,
      resp: 3,
      halt: 1
    ]

  import Plug.Conn.Status,
    only: [
      code: 1,
      reason_phrase: 1
    ]

  alias Geo.Polygon

  alias Plenario.TsRange

  alias Plenario.Actions.MetaActions

  alias Scrivener.Page

  # RENDERING UTILS

  @doc """
  This function slims down the logic that needs to be directly called in the controller. It takes
  the Plug connection, the view name, and the Scrivener results and computes the metadata that
  is attached to the response.

  It then calls the view module function to put these pieces together in a response.
  """
  @spec render_detail(Plug.Conn.t(), String.t(), Scrivener.Page.t() | Plenario.Schemas.Meta.t()) ::
          Plug.Conn.t()
  def render_detail(conn, view, page) do
    links = make_links(:detail, view, conn, page)
    counts = make_counts(view, page)
    params = fmt_params(conn)

    data =
      get_data(view, page)
      |> clean_data()
      |> format_data(:detail, view, conn.assigns[:format])

    Phoenix.Controller.render(
      conn,
      view,
      links: links,
      counts: counts,
      params: params,
      data: data
    )
  end

  @doc """
  This function slims down the logic that needs to be directly called in the controller. It takes
  the Plug connection, the view name, and the Scrivener results and computes the metadata that
  is attached to the response.

  It then calls the view module function to put these pieces together in a response.
  """
  @spec render_list(Plug.Conn.t(), String.t(), Scrivener.Page.t()) :: Plug.Conn.t()
  def render_list(conn, view, page) do
    links = make_links(:list, view, conn, page)
    counts = make_counts(view, page)
    params = fmt_params(conn)

    data =
      get_data(view, page)
      |> clean_data()
      |> format_data(:list, view, conn.assigns[:format])

    Phoenix.Controller.render(
      conn,
      view,
      links: links,
      counts: counts,
      params: params,
      data: data
    )
  end

  @doc """
  This function slims down the logic that needs to be directly called in the controller. It takes
  the Plug connection, the view name, and the Scrivener results and computes the metadata that
  is attached to the response.

  It then calls the view module function to put these pieces together in a response.
  """
  @spec render_aot(Scrivener.Page.t(), Plug.Conn.t(), String.t()) :: Plug.Conn.t()
  def render_aot(page, conn, view) do
    links = make_links(:aot, view, conn, page)
    counts = make_counts(view, page)
    params = fmt_params(conn)

    data =
      case view do
        "describe.json" ->
          get_data(view, page.entries)
          |> Enum.map(
            &Map.put(&1, :fields, [
              %{
                name: "node_id",
                type: "text"
              },
              %{
                name: "human_address",
                type: "text"
              },
              %{
                name: "latitude",
                type: "float"
              },
              %{
                name: "longitude",
                type: "float"
              },
              %{
                name: "timestamp",
                type: "timestamp"
              },
              %{
                name: "observations",
                type: "object"
              },
              %{
                name: "location",
                type: "geometry(point, 4326)"
              }
            ])
          )

        _ ->
          get_data(view, page)
      end

    data =
      data
      |> clean_data()
      |> format_data(:aot, view, conn.assigns[:format])

    Phoenix.Controller.render(
      conn,
      view,
      links: links,
      counts: counts,
      params: params,
      data: data
    )
  end

  # meta helpers

  defp make_links(controller, view, conn, page) do
    {prev_page_number, next_page_number} = get_prev_next_page_numbers(page)

    prev_url =
      case view do
        "get.json" ->
          make_url(controller, :get, conn, prev_page_number)

        _ ->
          nil
      end

    next_url =
      case view do
        "get.json" ->
          make_url(controller, :get, conn, next_page_number)

        _ ->
          nil
      end

    curr_url =
      case view do
        "get.json" ->
          make_url(controller, :get, conn, page.page_number)

        "head.json" ->
          make_url(controller, :head, conn, 1)

        "describe.json" ->
          make_url(controller, :describe, conn, 1)
      end

    %{
      previous: prev_url,
      current: curr_url,
      next: next_url
    }
  end

  defp make_counts(view, page) do
    case view do
      "describe.json" ->
        %{
          data_count: 1,
          total_pages: 1,
          total_records: 1
        }

      _ ->
        %{
          data_count: length(page.entries),
          total_pages: page.total_pages,
          total_records: page.total_entries
        }
    end
  end

  defp get_prev_next_page_numbers(%Page{total_pages: last, page_number: current}) do
    previous = if current == 1, do: nil, else: current - 1
    next = if current == last, do: nil, else: current + 1

    {previous, next}
  end

  defp get_prev_next_page_numbers(_), do: {nil, nil}

  defp make_url(:detail, _, _, nil), do: nil

  defp make_url(:detail, fun_atom, conn, page_number) do
    params = Map.merge(conn.params, %{"page" => page_number})
    slug = Map.get(conn.params, "slug")
    detail_url(conn, fun_atom, slug, params)
  end

  defp make_url(:list, _, _, nil), do: nil

  defp make_url(:list, fun_atom, conn, page_number) do
    params = Map.merge(conn.params, %{"page" => page_number})
    list_url(conn, fun_atom, params)
  end

  defp make_url(:aot, _, _, nil), do: nil

  defp make_url(:aot, fun_atom, conn, page_number) do
    params = Map.merge(conn.params, %{"page" => page_number})
    aot_url(conn, fun_atom, params)
  end

  defp fmt_params(conn) do
    page = conn.assigns[:page]
    size = conn.assigns[:page_size]
    {dir, field} = conn.assigns[:order_by]

    params = %{
      page: page,
      page_size: size,
      order_by: %{
        dir => field
      }
    }

    params =
      conn.assigns[:filters]
      |> Enum.reduce(params, fn {field, op, value}, params ->
        Map.put(params, field, %{op => value})
      end)

    params =
      case conn.assigns[:window] do
        nil ->
          params

        w ->
          Map.put(params, :window, Timex.format!(w, "%Y-%m-%dT%H:%M:%S", :strftime))
      end

    params
  end

  # data helpers

  defp get_data(view, page) do
    case view do
      "describe.json" ->
        page

      _ ->
        page.entries
    end
  end

  @scrub_keys [
    :__meta__,
    :__struct__,
    :id,
    :inserted_at,
    :updated_at,
    :source_type,
    :table_name,
    :state,
    :user_id,
    :meta_id,
    :aot_meta_id,
    :password,
    :password_hash
  ]

  @scrub_values [
    Ecto.Association.NotLoaded,
    Plug.Conn
  ]

  @doc """
  This function takes either a list of maps or a single map (map being either a literal map or a
  struct) and scrubs undesirable key/value pairs from it. Things like `__meta__` keys and
  `%Ecto.Association.NotLoaded{}` either bleed too much information and/or have serialization
  issues.

  See the module attributes `@scrub_keys` and `@scrub_values`.
  """
  @spec clean_data(list(map())) :: list(map())
  def clean_data(records) when is_list(records) do
    do_clean(records, [])
  end

  @spec clean_data(map()) :: map()
  def clean_data(record) when is_map(record) do
    Map.to_list(record)
    |> Enum.filter(fn {key, value} -> is_clean(key, value) end)
    |> Map.new()
  end

  defp do_clean([], acc) do
    Enum.reverse(acc)
  end

  defp do_clean([head | tail], acc) do
    cleaned = clean_data(head)
    do_clean(tail, [cleaned | acc])
  end

  for key <- @scrub_keys do
    defp is_clean(unquote(key), _), do: false
  end

  for value <- @scrub_values do
    defp is_clean(_, %unquote(value){}), do: false
  end

  defp is_clean(_, _), do: true

  defp format_data(data, :list, _, :json), do: data
  defp format_data(data, :list, _, :geojson), do: to_geojson(data, :bbox)

  defp format_data(data, :detail, "describe.json", :json), do: data
  defp format_data(data, :detail, "describe.json", :geojson), do: to_geojson(data, :bbox)

  defp format_data(data, :detail, _, :json), do: data

  defp format_data(data, :detail, _, :geojson) do
    {field, _} =
      data
      |> List.first()
      |> Enum.filter(fn {_, value} -> is_geom(value) end)
      |> List.first()

    to_geojson(data, field)
  end

  defp format_data(data, :aot, "describe.json", :json), do: data
  defp format_data(data, :aot, "describe.json", :geojson), do: to_geojson(data, :bbox)

  defp format_data(data, :aot, _, :json), do: data
  defp format_data(data, :aot, _, :geojson), do: to_geojson(data, :location)

  defp is_geom(%Geo.Point{}), do: true
  defp is_geom(%Geo.Polygon{}), do: true
  defp is_geom(_), do: false

  defp to_geojson(data, key) do
    data
    |> Enum.map(fn record ->
      case Map.pop(record, key) do
        {nil, _} ->
          nil

        {geom, record} ->
          %{
            type: "Feature",
            geometry: geom |> Geo.JSON.encode(),
            properties: record
          }
      end
    end)
    |> Enum.reject(&(&1 == nil))
  end

  # HALT

  @doc """
  This function applies a status and message, then stops processing a request. This cannot be
  inlined in a function, rather it needs to be used as the sole action of a function that
  pattern matches a result.

  ## Example

      def stuff(conn, params) do
        some_database_call(params)
        |> do_handle_stuff(conn)
      end

      defp do_handle_stuff({:error, message}, conn), do: halt_with(conn, :bad_request, message)

      defp do_handle_stuff({:ok, items}, conn), do: whatever
  """
  @spec halt_with(Plug.Conn.t(), atom() | integer()) :: Plug.Conn.t()
  def halt_with(conn, status) do
    status_code = code(status)
    message = reason_phrase(status_code)

    do_halt_with(conn, status_code, message)
  end

  @spec halt_with(Plug.Conn.t(), atom() | integer(), String.t()) :: Plug.Conn.t()
  def halt_with(conn, status, message) do
    status_code = code(status)
    do_halt_with(conn, status_code, message)
  end

  defp do_halt_with(conn, code, message) do
    body =
      %{error: message}
      |> Poison.encode!()

    conn
    |> put_resp_header("content-type", "application/json")
    |> resp(code, body)
    |> halt()
  end

  # CONTROLLER HELPERS -- FETCHING, VALIDATING, QUERYING

  @doc """
  This function validates that the slug is an integer and then attempts to get the Meta record
  associated to it. This will bounce requests that provide an ID or some other value that is
  not a slug.

  ## Example

      iex> validate_slug_get_meta(1)
      :error

      iex> validate_slug_get_meta("1")
      :error

      iex> validate_slug_get_meta("i-dont-exist")
      nil

      iex> validate_slug_get_meta("i-do-exist")
      %Meta{ ... }
  """
  @spec validate_slug_get_meta(String.t()) :: Plenario.Schemas.Meta.t() | :error | nil
  def validate_slug_get_meta(slug), do: validate_slug_get_meta(slug, [])

  @spec validate_slug_get_meta(String.t(), Keyword.t()) ::
          Plenario.Schemas.Meta.t() | :error | nil
  def validate_slug_get_meta(slug, opts) when is_bitstring(slug) do
    case Regex.match?(~r/^\d+$/, slug) do
      true ->
        nil

      false ->
        MetaActions.get(slug, opts)
    end
  end

  def validate_slug_get_meta(_, _), do: :error

  @doc """
  This function matches operators in the `conn.assigns[:whatever]` value tuple to an implementation
  where the operator and value are used to filter the field.

  Say we have a plug that plucks query parameters from the connection params, parses and validates
  them, and then assigns them to :filters. In the processing of the request we build an initial
  query and then iterate through the assigned filters and apply them to the query.

  What the signatures of this function do is match operators, and in select cases value types,
  to the proper application of the filter, rather than having to build the case by case logic into
  each time you need to dynamically apply conditions to a query.

  ## Example

      # Request comes in as /api/v2/aot?network_name=chicago&latitude=lt:42

      conn.assigns[:filters] = [
        {network_name, "eq", "chicago"},
        {latitude, "lt", "42"}
      ]

      query =
        conn.assigns[:filters]
        |> Enum.reduce(AotData, {fname, op, value}, query -> apply_filter(query, fname, op, value) end)

      Repo.all(query)
  """
  @spec apply_filter(Ecto.Queryable.t(), String.t(), String.t(), any()) :: Ecto.Queryable.t()
  def apply_filter(query, fname, "lt", value), do: where(query, [q], field(q, ^fname) < ^value)

  def apply_filter(query, fname, "le", value), do: where(query, [q], field(q, ^fname) <= ^value)

  def apply_filter(query, fname, "eq", value), do: where(query, [q], field(q, ^fname) == ^value)

  def apply_filter(query, fname, "ge", value), do: where(query, [q], field(q, ^fname) >= ^value)

  def apply_filter(query, fname, "gt", value), do: where(query, [q], field(q, ^fname) > ^value)

  def apply_filter(query, fname, "in", value), do: where(query, [q], field(q, ^fname) in ^value)

  def apply_filter(query, fname, "within", %TsRange{} = value),
    do: where(query, [q], timestamp_within(field(q, ^fname), ^TsRange.to_postgrex(value)))

  def apply_filter(query, fname, "within", %Polygon{} = value),
    do: where(query, [q], st_within(field(q, ^fname), ^value))

  def apply_filter(query, fname, "intersects", %TsRange{} = value),
    do: where(query, [q], tsrange_intersects(field(q, ^fname), ^TsRange.to_postgrex(value)))

  def apply_filter(query, fname, "intersects", %Polygon{} = value),
    do: where(query, [q], st_intersects(field(q, ^fname), ^value))
end
