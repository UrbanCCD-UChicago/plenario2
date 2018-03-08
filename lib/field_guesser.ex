defmodule Plenario.FieldGuesser do
  require Logger

  alias Plenario.Schemas.Meta

  def guess_field_types!(%Meta{} = meta) do
    Logger.info("beginning download of #{meta.source_url}")
    payload = download!(meta)

    filename = "/tmp/#{meta.slug}.#{meta.source_type}"
    Logger.info("writing contents to #{filename}")
    :ok = File.write(filename, payload)

    Logger.info("parsing #{filename}")
    rows = parse!(filename, 1_001, meta)
    Logger.info("got #{length(rows)} rows")

    Logger.info("ripping rows and making guesses")
    guesses =
      for row <- rows do
        for {key, value} <- row do
          {key, guess(value)}
        end
      end
      |> List.flatten()
    Logger.info("registered #{length(guesses)} guesses")
    Logger.debug("guesses = #{inspect(guesses)}")

    Logger.info("counting guess types per key")
    counts =
      Enum.reduce(guesses, %{}, fn x, acc ->
        Map.update(acc, x, 1, &(&1 + 1))
      end)
      |> Enum.into([])
    Logger.info("there are #{length(counts)} column/type pairs")
    Logger.debug("counts = #{inspect(counts)}")

    Logger.info("finding most frequently paired type to column")
    maxes =
      Enum.reduce(counts, %{}, fn {{k, _}, c}, acc ->
        curr = Map.get(acc, k, 0)
        if c > curr do
          Map.update(acc, k, c, &(&1 - &1 + c))
        else
          acc
        end
      end)
    Logger.info("max type counts per column = #{inspect(maxes)}")

    Logger.info("matching keys and max counts to types from counts")
    col_types =
      Enum.reduce(maxes, %{}, fn {col, max_c}, acc ->
        {{_, type}, _} = Enum.find(counts, fn {{k, _}, c} -> "#{k}" == "#{col}" and c == max_c end)
        Map.merge(acc, %{col => type})
      end)
    Logger.info("col types = #{inspect(col_types)}")

    col_types
  end

  defp download!(%Meta{source_type: "csv"} = meta), do: download_async!(meta)
  defp download!(%Meta{source_type: "tsv"} = meta), do: download_async!(meta)
  defp download!(meta) do
    %HTTPoison.Response{body: body} = HTTPoison.get!(meta.source_url)
    body
  end

  defp download_async!(meta) do
    {:ok, response} = HTTPoison.get(meta.source_url, %{}, stream_to: self)
    {:ok, messages} = receive_messages(response.id)

    messages
    |> Enum.reverse()
    |> Enum.join("")
    |> String.split("\n")
    |> Enum.drop(-1)
    |> Enum.join("\n")
  end

  defp receive_messages(id, limit \\ 10), do: receive_messages(id, limit, [])
  defp receive_messages(id, limit, acc) when length(acc) >= limit, do: {:ok, acc}
  defp receive_messages(id, limit, acc) do
    receive do
      %HTTPoison.AsyncStatus{id: ^id, code: 200} ->
        receive_messages(id, limit, acc)
      %HTTPoison.AsyncStatus{id: ^id, code: code} ->
        {:error, code}
      %HTTPoison.AsyncChunk{chunk: chunk} ->
        receive_messages(id, limit, [chunk | acc])
      %HTTPoison.AsyncEnd{id: ^id} ->
        {:ok, acc}
    end
  end

  defp parse!(filename, count, %Meta{source_type: "csv"}) do
    File.stream!(filename)
    |> CSV.decode!(headers: true)
    |> Enum.take(count)
  end

  defp parse!(filename, count, %Meta{source_type: "tsv"}) do
    File.stream!(filename)
    |> CSV.decode!(headers: true, separator: ?\t)
    |> Enum.take(count)
  end

  defp parse!(filename, count, %Meta{source_type: "json"}) do
    File.read!(filename)
    |> Poison.decode!()
    |> Enum.take(count)
  end

  defp parse!(filename, _, %Meta{source_type: "shp"}) do
    []
  end

  def guess(value) do
    cond do
      boolean?(value) -> "boolean"
      integer?(value) -> "integer"
      float?(value) -> "float"
      date?(value) -> "timestamptz"
      json?(value) -> "jsonb"
      true -> "text"
    end
  end

  def boolean?(value) when is_boolean(value), do: true
  def boolean?(value) when is_bitstring(value), do: Regex.match?(~r/^t$|^true$|^f$|^false$/i, value)
  def boolean?(value), do: false

  def integer?(value) when is_integer(value), do: true
  def integer?(value) when is_bitstring(value), do: Regex.match?(~r/^-?\d+$/, value)
  def integer?(value), do: false

  def float?(value) when is_float(value), do: true
  def float?(value) when is_bitstring(value), do: Regex.match?(~r/^-?\d+\.\d+$/, value)
  def float?(value), do: false

  def date?(value) when is_bitstring(value), do: Regex.match?(~r/\d{2,4}[-\/]\d{2}[-\/]\d{2,4}(.\d{1,2}:\d{1,2}:\d{1,2})?(.[ap]m)?/i, value)
  def date?(value), do: false

  def json?(value) when is_map(value) or is_list(value), do: true
  def json?(value) when is_bitstring(value) do
    case Poison.decode(value) do
      {:ok, _} -> true
      _ -> false
    end
  end
  def json?(value), do: false
end
