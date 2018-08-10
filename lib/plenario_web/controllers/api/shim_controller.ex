defmodule PlenarioWeb.Api.ShimController do
  @moduledoc """
  """

  use PlenarioWeb, :api_controller

  import Ecto.Query

  import PlenarioWeb.Api.Plugs

  import PlenarioWeb.Api.Utils,
    only: [
      apply_filter: 4,
      halt_with: 2,
      halt_with: 3
    ]

  alias Plenario.Repo

  alias Plenario.Actions.MetaActions

  alias Plenario.Schemas.Meta

  # SHIM SPECIFIC PLUGS

  defp check_dataset_name(conn, _opts) do
    case Map.get(conn.params, "dataset_name") do
      nil ->
        conn

      name ->
        slug = String.replace(name, "_", "-")
        assign(conn, :slug, {:slug, "eq", slug})
    end
  end

  defp check_obs_date(conn, _opts) do
    obs_date = Map.get(conn.params, "obs_date__ge")

    obs_date =
      case Map.get(conn.params, "obs_date__le") do
        nil ->
          obs_date

        value ->
          value
      end

    case obs_date do
      nil ->
        conn

      value ->
        case Timex.parse(value, "%Y-%m-%d", :strftime) do
          {:ok, date} ->
            assign(conn, :obs_date, {:time_range, "contains", date})

          _ ->
            halt_with(conn, :bad_request, "Could not parse observation date")
        end
    end
  end

  defp check_location_geom(conn, _opts) do
    case Map.get(conn.params, "location_geom__within") do
      nil ->
        conn

      value ->
        try do
          geom =
            Poison.decode!(value)
            |> Geo.JSON.decode()

          assign(conn, :geom, {:bbox, "intersects", geom})
        rescue
          _ ->
            halt_with(conn, :bad_request, "Could not parse bounding box")
        end
    end
  end

  plug(:check_page)
  plug(:check_page_size)
  plug(:check_order_by, default_order: "asc:name")
  plug(:check_dataset_name)
  plug(:check_obs_date)
  plug(:check_location_geom)

  # CONTROLLERS

  @spec datasets(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def datasets(conn, _params) do
    {dir, fname} = conn.assigns[:order_by]

    query =
      Meta
      |> where([m], m.state == ^"ready")
      |> order_by([m], [{^dir, ^fname}])
      |> preload(fields: :meta, virtual_dates: :meta, virtual_points: :meta)

    query =
      [conn.assigns[:slug], conn.assigns[:obs_date], conn.assigns[:geom]]
      |> Enum.reject(&is_nil/1)
      |> Enum.reduce(query, fn {fname, op, value}, query ->
        apply_filter(query, fname, op, value)
      end)

    try do
      page = conn.assigns[:page]
      page_size = conn.assigns[:page_size]
      data = Repo.paginate(query, page: page, page_size: page_size)
      render(conn, "datasets.json", data: data)
    rescue
      e in [Ecto.QueryError, Ecto.SubQueryError, Postgrex.Error] ->
        halt_with(conn, :bad_request, e.message)
    end
  end

  def fields(conn, %{"slug" => slug}) do
    slug =
      slug
      |> String.replace("_", "-")

    MetaActions.get(slug, with_fields: true, with_virtual_dates: true, with_virtual_points: true)
    |> do_fields(conn)
  end

  defp do_fields(%Meta{state: "ready"} = meta, conn), do: render(conn, "fields.json", meta: meta)

  defp do_fields(_, conn), do: halt_with(conn, :not_found)
end

# defmodule PlenarioWeb.Api.ShimController do
#   use PlenarioWeb, :api_controller
#   import PlenarioWeb.Api.Utils, only: [halt_with: 3]
#   alias Plenario.Actions.MetaActions
#   alias Plug.Conn

#   @translations %{
#     "dataset_name" => "slug"
#   }

#   @doc """
#   Handles V1 API queries for dataset metadata records. Translate provided
#   parameters from V1 API keywords to V2 API keywords. Then defers to the
#   ListController for V2.
#   """
#   def datasets(conn, _) do
#     %{conn | params: translate(conn.params)}
#     |> adapt_limit()
#     |> adapt_offset()
#     |> PlenarioWeb.Api.ListController.call(:describe)
#   end

#   @doc """
#   Handles V1 API queries for dataset records. Translate provided parameters
#   from V1 API keywords to V2 API keywords. Then defers to the DetailController
#   for V2.
#   """
#   def detail(conn, %{"dataset_name" => _}) do
#     %{conn | params: translate(conn.params)}
#     |> adapt_obs_date()
#     |> adapt_location_geom()
#     |> adapt_limit()
#     |> adapt_offset()
#     |> PlenarioWeb.Api.DetailController.call(:get)
#   end

#   @doc """
#   Params didn't come with a 'dataset_name'? VERBOTEN.
#   """
#   def detail(conn, _) do
#     halt_with(conn, 422, "'dataset_name' is a required parameter!")
#   end

#   @doc """
#   If a client specified a "obs_date" in one of their queries, take it
#   and swap it out with the name of the first timestamp field we can
#   find.

#   If there is no timestamp field present, then the request needs to halt
#   as the query will not be valid.
#   """
#   def adapt_obs_date(conn = %Conn{params: %{"obs_date" => datetime}}) do
#     meta = MetaActions.get(conn.params["slug"], with_fields: true)

#     case Enum.find(meta.fields, fn field -> field.type == "timestamp" end) do
#       nil ->
#         halt_with(conn, 422, "There are no timestamp fields for an 'obs_date' query to use.")

#       field ->
#         params =
#           conn.params
#           |> Map.delete("obs_date")
#           |> Map.put(field.name, datetime)

#         %{conn | params: params}
#     end
#   end

#   @doc """
#   No "obs_date"? Nothing to do then. Pass it through.
#   """
#   def adapt_obs_date(conn) do
#     conn
#   end

#   @doc """
#   If a client specified a "location_geom" in one of their queries, take it
#   and swap it out with the name of the first virtual point field we can
#   find.

#   If there is no virtual point field present, then the request needs to halt
#   as the query will not be valid.
#   """
#   def adapt_location_geom(conn = %Conn{params: %{"location_geom" => geom}}) do
#     meta =
#       MetaActions.get(
#         conn.params["slug"],
#         with_data_set_fields: true,
#         with_virtual_points: true,
#         with_virtual_dates: true
#       )

#     # Snips off the `within` prefix of the geometry. This is so that later on
#     # we can prepend the V2 compliant `in` keyword.
#     [_, geom] = String.split(geom, ":", parts: 2)

#     case Enum.find(meta.virtual_points, fn field -> not is_nil(field) end) do
#       nil ->
#         halt_with(
#           conn,
#           422,
#           "There are no virtual point fields to use with a " <>
#             "'location_geom' query. You might be looking at the wrong dataset. " <>
#             "Have a look at `/api/v2/datasets/#{meta.slug}` to see if this is " <>
#             "the data you want."
#         )

#       field ->
#         params =
#           conn.params
#           |> Map.delete("location_geom")
#           # Prefixing the geojson with `in:` creates a V2 API `contains` query.
#           # "Give me all the values that contained within this geometry".
#           |> Map.put(field.name, "in:" <> geom)

#         %{conn | params: params}
#     end
#   end

#   @doc """
#   No "location_geom"? Nothing to do then. Pass it through.
#   """
#   def adapt_location_geom(conn) do
#     conn
#   end

#   @doc """
#   Checks that the limit parameter is able to be parsed into an integer.
#   """
#   def adapt_limit(conn = %Conn{params: %{"limit" => limit}}) when is_binary(limit) do
#     case Integer.parse(limit) do
#       {limit, _} ->
#         %{conn | params: Map.put(conn.params, "limit", limit)} |> adapt_limit()

#       :error ->
#         halt_with(conn, 422, "limit value #{limit} must be an integer!")
#     end
#   end

#   @doc """
#   If the limit parameter is a valid integer, replace it's key with `page_size`.
#   """
#   def adapt_limit(conn = %Conn{params: %{"limit" => limit}}) do
#     params =
#       conn.params
#       |> Map.delete("limit")
#       |> Map.put("page_size", limit)

#     %{conn | params: params}
#   end

#   @doc """
#   If no limit parameter is present, drop in the default page size value.
#   """
#   def adapt_limit(conn) do
#     %{conn | params: Map.put(conn.params, "page_size", 500)}
#   end

#   @doc """
#   Offset is the way V1 clients would paginate through results. The number it represents
#   is the total amount of rows to skip before returning. In this way, it is analogous
#   to the `page` number, but it takes a little bit of math.

#   For example, with a limit of 10 and an offset of 20, what you're really asking for
#   is page 3.

#   In order for us to do this little bit of math, offset and page_size have to be integer
#   values.
#   """
#   def adapt_offset(conn = %Conn{params: %{"offset" => offset, "page_size" => page_size}})
#       when is_integer(offset) and is_integer(page_size) do
#     params =
#       conn.params
#       |> Map.delete("offset")
#       |> Map.put("page", offset / page_size + 1)

#     %{conn | params: params}
#   end

#   @doc """
#   Check that the binary provided for offset can be parsed into an integer.
#   """
#   def adapt_offset(conn = %Conn{params: %{"offset" => offset}}) when is_binary(offset) do
#     case Integer.parse(offset) do
#       {offset, _} ->
#         %{conn | params: Map.put(conn.params, "offset", offset)} |> adapt_offset()

#       :error ->
#         halt_with(conn, 422, "offset value #{offset} must be an integer!")
#     end
#   end

#   @doc """
#   If there's no offset just pass the connection struct through.
#   """
#   def adapt_offset(conn) do
#     conn
#   end

#   @doc """
#   Takes a map, presumably containing keys that correspond to the V1 API, and
#   converts them to keys that correspond to the V2 API.

#   Keys are translated using a map provided by @translations.

#   If a key isn't found in @translations, it is simply passed through. This is
#   because the key could possibly correspond to a data set column, and will be
#   validated dynamically.

#   ## Examples

#       iex> params = [{"foo__gt", "bar"}, {"baz__eq", "buzz"}]
#       iex> translate(params)
#       [{"foo", "gt:bar"}, {"baz", "eq:buzz"}]

#   """
#   def translate(params) when is_list(params) do
#     translate(params, [])
#   end

#   @doc """
#   Our params are a map? Convert it to a list and toss it back up.

#   ## Examples

#       iex> params = %{"foo_gt" => "bar", "baz__eq" => "buzz"}
#       iex> translate(params)
#       [{"foo", "gt:bar"}, {"baz", "eq:buzz"}]

#   """
#   def translate(params) when is_map(params) do
#     params
#     |> Map.to_list()
#     |> translate()
#   end

#   @doc """
#   Have we run out of params to translate? Noice, we've hit our base case. Take
#   our collection of tuples in the `acc`umulator and return a map.
#   """
#   def translate([], acc) do
#     Map.new(acc)
#   end

#   @doc """
#   Takes a collection of 2n tuples where the first value represents a key, and
#   the second value represents a value.

#   If the key corresponds to a V1 API keyword, convert it. Otherwise just pass
#   the tuple along into the `acc`umulator.

#   If the key contains a dunder `__` operator. Convert both it and and the value
#   to the V2 compliant `PARAM=OPERATOR:VALUE` format.

#   ## Examples

#       iex> params = [
#       ...>   {"dataset_name", "dset"},
#       ...>   {"foo__gt", "bar"},
#       ...>   {"baz__eq", "buzz"}
#       ...> ]
#       iex> translate(params)
#       [{"slug", "dset"}, {"foo", "gt:bar"}, {"baz", "eq:buzz"}]

#   """
#   def translate([{key, value} | params], acc) do
#     param =
#       {key, value}
#       |> format_key_value_pair()
#       |> translate_key_value_pair()

#     translate(params, [param | acc])
#   end

#   @doc """
#   Formats V1 style queries as V2 style queries if applicable.

#   ## Examples

#       iex> format_key_value_pair({"foo__gt", "bar"})
#       {"foo", "gt:bar"}

#   """
#   def format_key_value_pair({key, value}) do
#     case String.split(key, "__", parts: 2) do
#       [column, operator] -> {column, operator <> ":" <> value}
#       [column] -> {column, value}
#     end
#   end

#   @doc """
#   Takes key value pairs and translates the coverts the V1 API key to a V2 API
#   key if applicable.

#   Makes use of the `@translations` map provided by this module.

#   ## Examples

#       iex> translate_key_value_pair({"dataset_name", "foo"})
#       {"slug", "foo"}

#   """
#   def translate_key_value_pair({key, value}) do
#     case @translations[key] do
#       nil -> {key, value}
#       translated_key -> {translated_key, value}
#     end
#   end
# end
