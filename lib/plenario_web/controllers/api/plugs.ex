defmodule PlenarioWeb.Api.Plugs do
  @moduledoc """
  """

  import PlenarioWeb.Api.Utils,
    only: [
      halt_with: 3
    ]

  import Plug.Conn,
    only: [
      assign: 3
    ]

  alias Plenario.TsRange

  alias Plug.Conn

  # CHECK PAGE SIZE

  @max_page_size 5_000

  @default_page_size 200

  @page_size_error "`page_size` must be a positive integer less than or equal to #{@max_page_size}"

  @doc """
  This function validates that a given `page_size` parameter is a positive integer that is
  at most the default set by the module attribute `@max_page_size`. If no value is given,
  it uses the default page size set in the module attribute `@default_page_size`.

  If the value satisfies that, is is assigned to the connection as :page_size in its parsed
  integer form.

  If it doesn't satisfy the restrictions, it errors back to the client.
  ## Example

      # request comes in as /api/v2/data-sets?page_size=100
      conn.assigns[:page_size] = 100

      # request comes in as /api/v2/data-sets
      conn.assigns[:page_size] = @default_page_size
  """
  @spec check_page_size(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def check_page_size(%Conn{params: %{"page_size" => size}} = conn, _opts)
      when is_integer(size) and size > 0 and size <= @max_page_size,
      do: assign(conn, :page_size, size)

  def check_page_size(%Conn{params: %{"page_size" => size}} = conn, _opts)
      when is_integer(size) and size > @max_page_size,
      do: halt_with(conn, :bad_request, @page_size_error)

  def check_page_size(%Conn{params: %{"page_size" => size}} = conn, _opts)
      when is_integer(size) and size <= 0,
      do: halt_with(conn, :bad_request, @page_size_error)

  def check_page_size(%Conn{params: %{"page_size" => size}} = conn, _opts) when is_bitstring(size) do
    case Integer.parse(size) do
      {value, ""} ->
        %Conn{conn | params: Map.put(conn.params, "page_size", value)}
        |> check_page_size(nil)

      _ ->
        halt_with(conn, :bad_request, @page_size_error)
    end
  end

  def check_page_size(conn, _opts) do
    %Conn{conn | params: Map.put(conn.params, "page_size", @default_page_size)}
    |> check_page_size(nil)
  end

  # CHECK PAGE (NUMBER)

  @default_page 1

  @page_error "`page` must be a positive integer"

  @doc """
  This function validates that a given `page` paramter is a positive integer. If no value is given,
  it uses the value module attribute `@default_page`.

  If the value is a positive integer, it is assigned to the connection as :page in its parsed
  integer form.

  If it isn't, it errors back to the client.

  ## Example

      # request comes in as /api/v2/data-sets?page=4
      conn.assigns[:page] = 4

      # request comes in as /api/v2/data-sets
      conn.assigns[:page] = @default_page
  """
  @spec check_page(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def check_page(%Conn{params: %{"page" => page}} = conn, _opts)
      when is_integer(page) and page > 0,
      do: assign(conn, :page, page)

  def check_page(%Conn{params: %{"page" => page}} = conn, _opts)
      when is_integer(page) and page <= 0,
      do: halt_with(conn, :bad_request, @page_error)

  def check_page(%Conn{params: %{"page" => page}} = conn, _opts) when is_bitstring(page) do
    case Integer.parse(page) do
      {value, ""} ->
        %Conn{conn | params: Map.put(conn.params, "page", value)}
        |> check_page(nil)

      _ ->
        halt_with(conn, :bad_request, @page_error)
    end
  end

  def check_page(conn, _opts) do
    %Conn{conn | params: Map.put(conn.params, "page", @default_page)}
    |> check_page(nil)
  end

  # CHECK ORDER BY

  @order_error "`order_by` must follow format 'direction:field' where direction is either 'asc' or 'desc'"

  @doc """
  This function validates that a given `order_by` parameter matches the pattern `asc|desc:value`.
  If no value is given, it uses the value given in the function's options key `:default_order`.

  If the parameter satisfies the pattern, it is assigned to the connection as a tuple consisting
  of the atomized versions fo the direction and the field name under the :order_by key.

  If it doesn't match up, it errors back to the client.

  ## Example

      # request comes in as /api/v2/data-sets?order_by=desc:timestamp
      conn.assigns[:order_by] = {:desc, :timestamp}

      # plug assigned in controller as
      plug :check_order_by, default_order: "asc:name"
      # request comes in as /api/v2/data-sets
      conn.assigns[:order_by] = {:asc, :name}
  """
  @spec check_order_by(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def check_order_by(%Conn{params: %{"order_by" => order}} = conn, _opts) when is_bitstring(order) do
    case Regex.match?(~r/^asc|desc\:/i, order) do
      true ->
        [dir, field] = String.split(order, ":", parts: 2)
        dir = String.downcase(dir)
        assign(conn, :order_by, {String.to_atom(dir), String.to_atom(field)})

      false ->
        halt_with(conn, :bad_request, @order_error)
    end
  end

  def check_order_by(conn, opts) do
    %Conn{conn | params: Map.put(conn.params, "order_by", opts[:default_order])}
    |> check_order_by(nil)
  end

  # CHECK FILTERS

  @excluded_keys ["page", "page_size", "order_by", "slug", "dataset_name", "format", "window"]

  @acceptable_ops ["lt", "le", "eq", "ge", "gt", "in", "within", "intersects"]

  @tsrange_geom_ops ["within", "intersects"]

  @doc """
  This function picks up the parameters passed in requests to the API. The keys are then filtered
  to those not used in other plugs (see the `@excluded_keys` module attribute).

  From those key/values, it then inspects the values to check that they follow the pattern
  `op:value`. If there is no operator, it is assumed that strict equivalence was desired and we
  inject the `"eq"` operator.

  If the operator is not in the `@acceptable_ops` module attribute, the request is errored back
  to the client.

  For certain spectial operators (those in `@tsrange_geom_ops`) we go a step futher to parse and
  validate the value portion of the filter to ensure the database isn't hit with total trash. If
  we can determine that the value is not parseable into either struct, the client gets an error.

  Finally, once all of that is done we assign them as a list of tuples to :filters on the
  connection.

  ## Example

      # Request comes in as /api/v2/data-sets?page_size=2&page=4&order_by=asc:name\
      #  &last_updated=within:{"lower":"2018-01-01T00:00:00","upper":"2018-02-01T00:00L00","upper_inclusive":false}

      conn.assigns = [
        page: 4,
        page_size: 2
        order_by: {:asc, :name},
        filters: [
          {:last_updated, "within", %TsRange{lower: ~N[2018-01-01 00:00:00], upper: ~N[2018-01-01 00:00:00], upper_inclusive: false}}
        ]
      ]

      # Request comes in as /api/v2/data-sets?page_size=2&page=4&order_by=asc:name\
      #  &last_updated=within:the-last-week

      halt_with(conn, :bad_request, "Could not parse value for `last_updated`")
  """
  @spec check_filters(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def check_filters(%Conn{params: params} = conn, _opts) when is_map(params) do
    params =
      params
      |> Enum.reject(fn {key, _} -> key in @excluded_keys end)

    {params, errors} =
      params
      |> Enum.reduce({[], []}, fn {field, filter}, {params, errors} ->
        [op, value] =
          case is_list(filter) do
            true ->
              ["in", filter]

            false ->
              try do
                [o, v] = String.split(filter, ":", parts: 2)
                [o, v]
              rescue
                MatchError ->
                  ["eq", filter]
              end
          end

        case op in @acceptable_ops do
          true ->
            params = params ++ [{String.to_atom(field), op, value}]
            {params, errors}

          false ->
            errors = errors ++ [field]
            {params, errors}
        end
      end)

    check_params_errors({params, errors}, conn)
  end

  def check_filters(conn, _opts), do: conn

  defp check_params_errors({_, errors}, conn) when is_list(errors) and length(errors) > 0 do
    fields =
      errors
      |> Enum.join(", ")

    message = "Could not parse filters for field(s) #{fields}"
    halt_with(conn, :bad_request, message)
  end

  defp check_params_errors({params, _}, conn) do
    {params, errors} =
      params
      |> Enum.reduce({[], []}, fn {field, op, value}, {params, errors} ->
        case op in @tsrange_geom_ops do
          false ->
            params = params ++ [{field, op, value}]
            {params, errors}

          true ->
            value =
              try do
                Poison.decode!(value, as: %TsRange{})
              rescue
                _ ->
                  try do
                    Poison.decode!(value)
                    |> Geo.JSON.decode()
                  rescue
                    _ ->
                      :error
                  end
              end

            case value do
              :error ->
                errors = errors ++ [field]
                {params, errors}

              strukt ->
                params = params ++ [{field, op, strukt}]
                {params, errors}
            end
        end
      end)

    check_tsrange_geoms({params, errors}, conn)
  end

  defp check_tsrange_geoms({_, errors}, conn) when is_list(errors) and length(errors) > 0 do
    fields =
      errors
      |> Enum.join(", ")

    message = "Could not parse field(s) #{fields}"
    halt_with(conn, :bad_request, message)
  end

  defp check_tsrange_geoms({params, _}, conn), do: assign(conn, :filters, params)

  # APPLY WINDOW

  @doc """
  This function is used for the AoT Controller -- it checks for a `window` param and optionally
  sets it to the current timestamp if not found.

  The window is used in the queries to limit the data so that if a client is paging through
  the data set, the pagination remains stable during a freah load of more recent data.

  The function assigns :window as a NaiveDateTime struct for immediate query interpolation.
  """
  @spec apply_window(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def apply_window(%Conn{params: %{"window" => %NaiveDateTime{} = w}} = conn, _opts),
    do: assign(conn, :window, w)

  def apply_window(%Conn{params: %{"window" => window}} = conn, _opts) when is_bitstring(window) do
    case Timex.parse(window, "%Y-%m-%dT%H:%M:%S", :strftime) do
      {:ok, window} ->
        assign(conn, :window, window)

      _ ->
        halt_with(conn, :bad_request, "Could not parse value for `window`")
    end
  end

  def apply_window(conn, _opts) do
    now =
      NaiveDateTime.utc_now()
      |> Timex.format!("%Y-%m-%dT%H:%M:%S", :strftime)

    %Conn{conn | params: Map.put(conn.params, "window", now)}
    |> apply_window(nil)
  end

  # CHECK FORMAT

  @formats ["json", "geojson"]

  @format_error "`format` must be either 'json' or 'geojson'"

  @default_format :json

  @doc """
  This function checks for a `format` param. By default, the API will return data
  in JSON format. However, clients can request data be returned in GeoJSON format
  instead.

  The function assigns :format as an atom of either :json or :geojson for strict
  matching later in the pipeline.
  """
  @spec check_format(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def check_format(%Conn{params: %{"format" => fmt}} = conn, _opts) when is_atom(fmt),
    do: assign(conn, :format, fmt)

  def check_format(%Conn{params: %{"format" => fmt}} = conn, _opts)
      when is_bitstring(fmt) and fmt in @formats,
      do: assign(conn, :format, String.to_atom(fmt))

  def check_format(%Conn{params: %{"format" => _}} = conn, _opts),
    do: halt_with(conn, :bad_request, @format_error)

  def check_format(conn, _opts) do
    %Conn{conn | params: Map.put(conn.params, "format", @default_format)}
    |> check_format(nil)
  end
end
