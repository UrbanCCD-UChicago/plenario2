defmodule PlenarioWeb.Api.ViewUtils do
  @moduledoc """
  This module contains functions that are universally beneficial to API Views. These are functions
  that are used to format and clean responses.
  """

  @scrub_keys [
    :__meta__,
    :__struct__,
    :id,
    :inserted_at,
    :updated_at,
    :source_type,
    :table_name,
    :state,
    :user_id,
    :meta_id,
    :aot_meta_id,
    :password,
    :password_hash
  ]

  @scrub_values [
    Ecto.Association.NotLoaded,
    Plug.Conn
  ]

  @doc """
  This function takes either a list of maps or a single map (map being either a literal map or a
  struct) and scrubs undesirable key/value pairs from it. Things like `__meta__` keys and
  `%Ecto.Association.NotLoaded{}` either bleed too much information and/or have serialization
  issues.

  See the module attributes `@scrub_keys` and `@scrub_values`.
  """
  @spec clean(list(map())) :: list(map())
  def clean(records) when is_list(records) do
    clean(records, [])
  end

  @spec clean(map()) :: map()
  def clean(record) when is_map(record) do
    Map.to_list(record)
    |> Enum.filter(fn {key, value} -> is_clean(key, value) end)
    |> Map.new()
  end

  defp clean([], acc) do
    Enum.reverse(acc)
  end

  defp clean([head | tail], acc) do
    cleaned = clean(head)
    clean(tail, [cleaned | acc])
  end

  for key <- @scrub_keys do
    defp is_clean(unquote(key), _), do: false
  end

  for value <- @scrub_values do
    defp is_clean(_, %unquote(value){}), do: false
  end

  defp is_clean(_, _), do: true
end
