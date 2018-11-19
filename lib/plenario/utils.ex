defmodule Plenario.Utils do

  @fmts [
    "{ISO:Basic}",
    "{ISO:Basic:Z}",
    "{ISO:Extended}",
    "{ISO:Extended:Z}",
    # thanks socrata... f@#$%^& morons
    "{M}/{D}/{YYYY}",
    "{M}/{D}/{YYYY} {h12}:{m}:{s} {AM}"
  ]

  def parse_timestamp(value) do
    parse_timestamp(value, @fmts)
  end

  def parse_timestamp(value, [fmt | tail]) do
    case Timex.parse(value, fmt) do
      {:ok, value} -> value
      {:error, _} -> parse_timestamp(value, tail)
    end
  end

  def parse_timestamp(_, []), do: :error
end
