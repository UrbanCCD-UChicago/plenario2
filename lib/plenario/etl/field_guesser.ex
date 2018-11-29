defmodule Plenario.Etl.FieldGuesser do
  require Logger

  import Plenario.Utils, only: [parse_timestamp: 1]

  alias Plenario.DataSet

  alias Plenario.Etl.Downloader

  alias Socrata.Client

  @download_limit 10  # chunks

  @num_rows 1_001

  @soc_types %{
    "calendar_date" => "timestamp",
    "checkbox" => "boolean",
    "double" => "float",
    "floating_timestamp" => "timestamp",
    "line" => "geometry",
    "location" => "jsonb",
    "money" => "text",
    "multiline" => "geometry",
    "multipoint" => "geometry",
    "multipolygon" => "geometry",
    "number" => "integer",
    "point" => "geometry",
    "polygon" => "geometry",
    "text" => "text"
  }

  # socrata
  def guess(%DataSet{soc_domain: domain, soc_4x4: fourby, socrata?: true}) do
    %HTTPoison.Response{body: body} = Client.new(domain) |> Client.get_view(fourby)
    res = Jason.decode!(body)

    fields =
      res["columns"]
      |> Enum.map(fn col -> [col["fieldName"], col["dataTypeName"], col["description"]] end)
      |> Enum.reject(fn [key, _, _] -> String.starts_with?(key, ":@") end)
      |> Enum.map(fn [col, type, desc] -> [col, Map.get(@soc_types, type, "text"), desc] end)

    fields =
      fields ++
      [
        [":id", "text", "The internal Socrata record ID"],
        [":created_at", "timestamp", "The timestamp of when the record was first created"],
        [":updated_at", "timestamp", "The timestamp of when the record was last updated"]
      ]

    fields
    |> Enum.map(& Enum.zip(~w|name type description|a, &1))
    |> Enum.map(& Enum.into(&1, %{}))
  end

  # web resource
  def guess(%DataSet{src_type: type, socrata?: false} = ds) do
    source_doc = Downloader.download(ds, @download_limit)

    csv_opts =
      case type do
        "csv" -> [headers: true]
        "tsv" -> [headers: true, separator: ?\t]
      end

    rows =
      File.stream!(source_doc)
      |> CSV.decode!(csv_opts)
      |> Enum.take(@num_rows)

    guesses =
      rows
      |> Enum.map(fn row_map ->
        Enum.map(row_map, fn {key, value} ->
          {key, make_guess(value)}
        end)
      end)
      |> List.flatten()

    counts =
      guesses
      |> Enum.reduce(%{}, fn key_guess, acc ->
        Map.update(acc, key_guess, 1, & &1 + 1)
      end)
      |> Enum.into([])

    maxes =
      counts
      |> Enum.reduce(%{}, fn {{key, _type?}, count}, acc ->
        current_max = Map.get(acc, key, 0)
        case count > current_max do
          false -> acc
          true -> Map.put(acc, key, count)
        end
      end)

    maxes
    |> Enum.reduce(%{}, fn {col, count}, acc ->
      # this is kind of convoluted, but we need to match the column
      # and the max count to the previous `counts` map to ensure we
      # are setting the correct type
      {{_col, type,}, _count} = Enum.find(counts, fn {{col?, _type}, count?} -> col? == col and count? == count end)
      Map.put(acc, col, type)
    end)
    |> Enum.map(fn {name, type} -> [name: name, type: type] end)
    |> Enum.map(& Enum.into(&1, %{}))
  end

  def make_guess(value) do
    cond do
      boolean?(value) -> "boolean"
      integer?(value) -> "integer"
      float?(value) -> "float"
      date?(value) -> "timestamp"
      json?(value) -> "jsonb"
      geometry?(value) -> "geometry"
      true -> "text"
    end
  end

  def boolean?(value) when is_boolean(value), do: true
  def boolean?(value) when is_binary(value), do: Regex.match?(~r/^(t|true|f|false)$/i, value)
  def boolean?(_), do: false

  def integer?(value) when is_integer(value), do: true
  def integer?(value) when is_binary(value), do: Regex.match?(~r/^-?\d+$/, value)
  def integer?(_), do: false

  def float?(value) when is_float(value), do: true
  def float?(value) when is_binary(value), do: Regex.match?(~r/^-?\d+\.\d+$/, value)
  def float?(_), do: false

  def date?(value) when is_binary(value), do: parse_timestamp(value) != :error
  def date?(_), do: false

  def geometry?(value) when is_binary(value), do: Regex.match?(~r/^(multi)?(point|polygon|linestring)\s?\(.*$/i, value)
  def geometry?(_), do: false

  def json?(value) when is_map(value) or is_list(value), do: true
  def json?(value) when is_binary(value) do
    case Jason.decode(value) do
      {:ok, _} -> true
      {:error, _} -> false
    end
  end
  def json?(_), do: false
end
