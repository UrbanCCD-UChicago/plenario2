defmodule PlenarioWeb.Controllers.Api.CaptureArgs do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, opts) do
    conn.params
    |> Map.split(opts[:fields])
    |> elem(0)
    |> Stream.map(&split_value/1)
    |> Enum.map(&to_condition_tuple/1)
    |> (&assign(conn, opts[:assign], &1)).()
  end

  defp split_value({col, val}), do: {col, String.split(val, ":", parts: 2)}
  defp to_condition_tuple({col, [val]}), do: {col, val}
  defp to_condition_tuple({col, [op, val]}), do: {col, {op, val}}
end
