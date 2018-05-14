defmodule PlenarioWeb.Controllers.Api.CaptureArgs do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, opts) do
    conn.params
    |> Map.split(opts[:fields])
    |> elem(0)
    |> Stream.map(&split_value/1)
    |> Stream.map(&to_condition_tuple/1)
    |> Enum.map(&cast/1)
    |> (&assign(conn, opts[:assign], &1)).()
  end

  defp split_value({col, val}), do: {col, String.split(val, ":", parts: 2)}
  defp to_condition_tuple({col, [val]}), do: {col, val}
  defp to_condition_tuple({col, [op, val]}), do: {col, {op, val}}

  defp cast({col, {op, val}}) when is_binary(val) do
    val = URI.decode(val)

    val = case Poison.decode(val) do
      {:error, {:invalid, _, _}} -> val
      {:ok, map} -> 
        try do
          %{Geo.JSON.decode(map) | srid: 4326}
        rescue
          Geo.JSON.DecodeError -> map
        end
    end

    {col, {op, val}}
  end

  defp cast({col, val}), do: {col, val}
end
