defmodule PlenarioWeb.ApiControllerUtils do
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

  alias Plug.Conn

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

  @doc """
  Gets the client's expected response format.
  """
  @spec resp_format(Plug.Conn.t()) :: String.t()
  def resp_format(%Conn{params: %{"format" => "geojson"}}), do: "geojson"
  def resp_format(_), do: "json"

  @doc """
  Decodes GeoJSON parameters.
  """
  @spec decode_geojson(map()) :: {:ok, Geo.Polygon.t()} | {:error, nil}
  def decode_geojson(%{"geometry" => %{"type" => _, "coordinates" => _} = geom}),
    do: Geo.JSON.decode(geom)

  def decode_geojson(%{"type" => _, "coordinates" => _} = geom),
    do: Geo.JSON.decode(geom)

  def decode_geojson(_), do: {:error, nil}

  @doc """
  """
  @spec meta(fun(), atom(), Plug.Conn.t()) :: map()
  def meta(url_func, controller_func, %Conn{assigns: assigns} = conn, instance \\ nil) do
    query =
      assigns
      |> Enum.reject(fn {key, _} -> key == :admin_nav? end)
      |> Enum.map(fn {key, value} ->
        value = encode_value(value)
        {key, value}
      end)
      |> Enum.into(%{})

    links =
      case instance do
        nil ->
          %{
            previous: prev_link(url_func, controller_func, conn),
            current: url_func.(conn, controller_func, conn.params),
            next: next_link(url_func, controller_func, conn)
          }

        _ ->
          %{
            previous: prev_link(url_func, controller_func, instance, conn),
            current: url_func.(conn, controller_func, instance, conn.params),
            next: next_link(url_func, controller_func, instance, conn)
          }
      end

    %{query: query, links: links}
  end

  defp encode_value(value) do
    cond do
      is_tuple(value) ->
        Tuple.to_list(value)
        |> Enum.map(&encode_value/1)

      is_map(value) and Map.has_key?(value, :coordinates) ->
        Geo.JSON.encode(value)

      true ->
        value
    end
  end

  defp prev_link(_, _, %Conn{params: %{"page" => 1}}), do: nil

  defp prev_link(url_func, controller_func, %Conn{params: %{"page" => page} = params} = conn),
    do: url_func.(conn, controller_func, Map.put(params, "page", page - 1))

  defp prev_link(_, _, _, %Conn{params: %{"page" => 1}}), do: nil

  defp prev_link(url_func, controller_func, instance, %Conn{params: %{"page" => page} = params} = conn),
    do: url_func.(conn, controller_func, instance, Map.put(params, "page", page - 1))

  defp next_link(url_func, controller_func, %Conn{params: %{"page" => page} = params} = conn),
    do: url_func.(conn, controller_func, Map.put(params, "page", page + 1))

  defp next_link(url_func, controller_func, instance, %Conn{params: %{"page" => page} = params} = conn),
    do: url_func.(conn, controller_func, instance, Map.put(params, "page", page + 1))
end
