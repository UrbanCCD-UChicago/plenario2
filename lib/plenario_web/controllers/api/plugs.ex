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

  @default_order "asc:row_id"

  @order_error "`order_by` must follow format 'direction:field' where direction is either 'asc' or 'desc'"

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

  def check_order_by(conn, _opts) do
    %Conn{conn | params: Map.put(conn.params, "order_by", @default_order)}
    |> check_order_by(nil)
  end

  # CHECK FILTERS

  @excluded_keys ["page", "page_size", "order_by", "slug"]

  @acceptable_ops ["lt", "le", "eq", "ge", "gt", "within", "intersects"]

  @tsrange_geom_ops ["within", "intersects"]

  @spec check_filters(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def check_filters(%Conn{params: params} = conn, _opts) when is_map(params) do
    params =
      params
      |> Enum.reject(fn {key, _} -> key in @excluded_keys end)

    {params, errors} =
      params
      |> Enum.reduce({[], []}, fn {field, filter}, {params, errors} ->
        [op, value] =
          try do
            String.split(filter, ":", parts: 2)
          rescue
            MatchError ->
              ["eq", filter]
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
                    Geo.JSON.DecodeError ->
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
end
