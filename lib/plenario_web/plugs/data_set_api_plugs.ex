defmodule PlenarioWeb.DataSetApiPlugs do
  import PlenarioWeb.ApiControllerUtils

  import Plenario.Utils, only: [parse_timestamp: 1]

  import Plug.Conn

  alias Plug.Conn

  @bbox_error "could not parse value for bbox"

  def bbox(%Conn{params: %{"bbox" => bbox}} = conn, _) do
    String.split(bbox, ":", parts: 2)
    |> do_bbox(conn)
  end

  def bbox(conn, _), do: conn

  defp do_bbox([op, geom], conn) when op in ~w|contains intersects| do
    parse_geom(geom)
    |> handle_bbox_op(op, conn)
  end

  defp do_bbox(_, conn), do: halt_with(conn, :bad_request, @bbox_error)

  defp handle_bbox_op(:error, _, conn), do: halt_with(conn, :bad_request, @bbox_error)

  defp handle_bbox_op(geom, "contains", conn), do: assign(conn, :bbox_contains, geom)

  defp handle_bbox_op(geom, "intersects", conn), do: assign(conn, :bbox_intersects, geom)

  defp parse_geom(geom) do
    try do
      Jason.decode!(geom)
      |> Geo.JSON.decode()
    rescue
      _ ->
        :error
    end
  end

  @timerange_error "could not parse value for time_range"

  def time_range(%Conn{params: %{"time_range" => range}} = conn, _) do
    String.split(range, ":", parts: 2)
    |> do_time_range(conn)
  end

  def time_range(conn, _), do: conn

  defp do_time_range([op, range], conn) when op in ~w|contains intersects| do
    Jason.decode(range)
    |> parse_time_range()
    |> handle_time_range_op(op, conn)
  end

  defp do_time_range(_, conn), do: halt_with(conn, :bad_request, @timerange_error)

  defp handle_time_range_op(:error, _, conn), do: halt_with(conn, :bad_request, @timerange_error)

  defp handle_time_range_op(timestamp, "contains", conn), do: assign(conn, :time_range_contains, timestamp)

  defp handle_time_range_op(range, "intersects", conn), do: assign(conn, :time_range_intersects, range)

  defp parse_time_range({:error, %Jason.DecodeError{data: timestamp}}), do: parse_timestamp(timestamp)

  defp parse_time_range({:ok, json}) do
    try do
      mapped =
        json
        |> Enum.map(fn {key, value} -> {"#{key}", value} end)
        |> Enum.into(%{})

      Plenario.TsRange.new(
        Map.get(mapped, "lower") |> parse_timestamp(),
        Map.get(mapped, "upper") |> parse_timestamp(),
        Map.get(mapped, "lower_inclusive", true),
        Map.get(mapped, "upper_inclusive", false)
      )
    rescue
      _ ->
        :error
    end
  end
end
